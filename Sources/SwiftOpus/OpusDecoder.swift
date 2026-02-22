import AVFoundation
import Accelerate
import Foundation

public final class OpusDecoder: @unchecked Sendable {
    public let configuration: OpusDecoderConfiguration
    public let outputFormat: AVAudioFormat

    private enum Backend {
        case single(OpaquePointer)
        case multistream(OpaquePointer)
    }

    private let lock = NSLock()
    private let backend: Backend
    private var floatScratch: [Float]
    private var int16Scratch: [Int16]

    public init(configuration: OpusDecoderConfiguration) throws {
        self.configuration = configuration
        outputFormat = try configuration.avAudioFormat

        let backend: Backend
        if configuration.usesMultistreamDecoder {
            let layout = try configuration.multistreamLayout ?? OpusChannelLayout.standardSurround(
                for: configuration.channels
            )
            var createErrorCode: Int32 = OPUS_OK
            let pointer = layout.mapping.withUnsafeBufferPointer { mappingBuffer in
                opus_multistream_decoder_create(
                    configuration.sampleRate.rawValue,
                    Int32(configuration.channels),
                    Int32(layout.streamCount),
                    Int32(layout.coupledStreamCount),
                    mappingBuffer.baseAddress!,
                    &createErrorCode
                )
            }
            guard let pointer else {
                throw SwiftOpus.OpusError(createErrorCode)
            }
            try SwiftOpus.throwOnOpusError(createErrorCode)
            backend = .multistream(pointer)
        } else {
            var createErrorCode: Int32 = OPUS_OK
            guard let pointer = opus_decoder_create(
                configuration.sampleRate.rawValue,
                Int32(configuration.channels),
                &createErrorCode
            ) else {
                throw SwiftOpus.OpusError(createErrorCode)
            }
            try SwiftOpus.throwOnOpusError(createErrorCode)
            backend = .single(pointer)
        }

        self.backend = backend

        let scratchSampleCount = configuration.maximumSamplesPerChannel * configuration.channels
        floatScratch = [Float](repeating: 0, count: scratchSampleCount)
        int16Scratch = [Int16](repeating: 0, count: scratchSampleCount)
    }

    deinit {
        lock.lock()
        defer { lock.unlock() }
        switch backend {
        case let .single(pointer):
            opus_decoder_destroy(pointer)
        case let .multistream(pointer):
            opus_multistream_decoder_destroy(pointer)
        }
    }

    public func decodeInterleavedFloat(
        payload: Data,
        decodeFEC: Bool = false,
        into destination: UnsafeMutableBufferPointer<Float>
    ) throws -> Int {
        try payload.withUnsafeBytes { payloadBuffer in
            try decodeInterleavedFloat(
                payload: payloadBuffer,
                decodeFEC: decodeFEC,
                into: destination
            )
        }
    }

    public func decodeInterleavedFloat(
        payload: UnsafeRawBufferPointer,
        decodeFEC: Bool = false,
        into destination: UnsafeMutableBufferPointer<Float>
    ) throws -> Int {
        let requiredSampleCount = configuration.maximumSamplesPerChannel * configuration.channels
        guard destination.count >= requiredSampleCount else {
            throw SwiftOpus.RuntimeError.bufferTooSmall(
                expectedMinimum: requiredSampleCount,
                actual: destination.count
            )
        }

        guard payload.count > 0 else {
            return 0
        }
        guard payload.count <= Int(Int32.max) else {
            throw SwiftOpus.RuntimeError.invalidPacketSize(payload.count)
        }

        lock.lock()
        defer { lock.unlock() }

        let decodedFrameCount: Int32
        switch backend {
        case let .single(pointer):
            decodedFrameCount = opus_decode_float(
                pointer,
                payload.bindMemory(to: UInt8.self).baseAddress,
                Int32(payload.count),
                destination.baseAddress!,
                Int32(configuration.maximumSamplesPerChannel),
                decodeFEC ? 1 : 0
            )
        case let .multistream(pointer):
            decodedFrameCount = opus_multistream_decode_float(
                pointer,
                payload.bindMemory(to: UInt8.self).baseAddress,
                Int32(payload.count),
                destination.baseAddress!,
                Int32(configuration.maximumSamplesPerChannel),
                decodeFEC ? 1 : 0
            )
        }

        if decodedFrameCount < 0 {
            throw SwiftOpus.OpusError(decodedFrameCount)
        }

        return Int(decodedFrameCount)
    }

    public func decodeInterleavedInt16(
        payload: Data,
        decodeFEC: Bool = false,
        into destination: UnsafeMutableBufferPointer<Int16>
    ) throws -> Int {
        try payload.withUnsafeBytes { payloadBuffer in
            try decodeInterleavedInt16(
                payload: payloadBuffer,
                decodeFEC: decodeFEC,
                into: destination
            )
        }
    }

    public func decodeInterleavedInt16(
        payload: UnsafeRawBufferPointer,
        decodeFEC: Bool = false,
        into destination: UnsafeMutableBufferPointer<Int16>
    ) throws -> Int {
        let requiredSampleCount = configuration.maximumSamplesPerChannel * configuration.channels
        guard destination.count >= requiredSampleCount else {
            throw SwiftOpus.RuntimeError.bufferTooSmall(
                expectedMinimum: requiredSampleCount,
                actual: destination.count
            )
        }

        guard payload.count > 0 else {
            return 0
        }
        guard payload.count <= Int(Int32.max) else {
            throw SwiftOpus.RuntimeError.invalidPacketSize(payload.count)
        }

        lock.lock()
        defer { lock.unlock() }

        let decodedFrameCount: Int32
        switch backend {
        case let .single(pointer):
            decodedFrameCount = opus_decode(
                pointer,
                payload.bindMemory(to: UInt8.self).baseAddress,
                Int32(payload.count),
                destination.baseAddress!,
                Int32(configuration.maximumSamplesPerChannel),
                decodeFEC ? 1 : 0
            )
        case let .multistream(pointer):
            decodedFrameCount = opus_multistream_decode(
                pointer,
                payload.bindMemory(to: UInt8.self).baseAddress,
                Int32(payload.count),
                destination.baseAddress!,
                Int32(configuration.maximumSamplesPerChannel),
                decodeFEC ? 1 : 0
            )
        }

        if decodedFrameCount < 0 {
            throw SwiftOpus.OpusError(decodedFrameCount)
        }

        return Int(decodedFrameCount)
    }

    public func decodeToPCMBuffer(
        payload: Data,
        decodeFEC: Bool = false
    ) throws -> AVAudioPCMBuffer? {
        guard !payload.isEmpty else {
            return nil
        }

        switch configuration.pcmFormat {
        case .float32:
            return try decodeToFloatBuffer(payload: payload, decodeFEC: decodeFEC)
        case .int16:
            return try decodeToInt16Buffer(payload: payload, decodeFEC: decodeFEC)
        }
    }

    private func decodeToFloatBuffer(
        payload: Data,
        decodeFEC: Bool
    ) throws -> AVAudioPCMBuffer? {
        lock.lock()
        defer { lock.unlock() }

        let decodedFrameCount = try payload.withUnsafeBytes { payloadBuffer in
            try decodeInterleavedFloatLocked(
                payload: payloadBuffer,
                decodeFEC: decodeFEC,
                into: &floatScratch
            )
        }
        guard decodedFrameCount > 0 else {
            return nil
        }

        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(decodedFrameCount)
        ), let channelData = pcmBuffer.floatChannelData
        else {
            throw SwiftOpus.RuntimeError.allocationFailed
        }

        let channelCount = configuration.channels
        floatScratch.withUnsafeBufferPointer { sourceBuffer in
            guard let source = sourceBuffer.baseAddress else {
                return
            }
            for channelIndex in 0..<channelCount {
                cblas_scopy(
                    Int32(decodedFrameCount),
                    source.advanced(by: channelIndex),
                    Int32(channelCount),
                    channelData[channelIndex],
                    1
                )
            }
        }

        pcmBuffer.frameLength = AVAudioFrameCount(decodedFrameCount)
        return pcmBuffer
    }

    private func decodeToInt16Buffer(
        payload: Data,
        decodeFEC: Bool
    ) throws -> AVAudioPCMBuffer? {
        lock.lock()
        defer { lock.unlock() }

        let decodedFrameCount = try payload.withUnsafeBytes { payloadBuffer in
            try decodeInterleavedInt16Locked(
                payload: payloadBuffer,
                decodeFEC: decodeFEC,
                into: &int16Scratch
            )
        }
        guard decodedFrameCount > 0 else {
            return nil
        }

        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(decodedFrameCount)
        ), let channelData = pcmBuffer.int16ChannelData
        else {
            throw SwiftOpus.RuntimeError.allocationFailed
        }

        let channelCount = configuration.channels
        int16Scratch.withUnsafeBufferPointer { sourceBuffer in
            guard let source = sourceBuffer.baseAddress else {
                return
            }
            for channelIndex in 0..<channelCount {
                let target = channelData[channelIndex]
                var sourceIndex = channelIndex
                for frameIndex in 0..<decodedFrameCount {
                    target[frameIndex] = source[sourceIndex]
                    sourceIndex += channelCount
                }
            }
        }

        pcmBuffer.frameLength = AVAudioFrameCount(decodedFrameCount)
        return pcmBuffer
    }

    private func decodeInterleavedFloatLocked(
        payload: UnsafeRawBufferPointer,
        decodeFEC: Bool,
        into destination: inout [Float]
    ) throws -> Int {
        guard payload.count > 0 else {
            return 0
        }
        guard payload.count <= Int(Int32.max) else {
            throw SwiftOpus.RuntimeError.invalidPacketSize(payload.count)
        }

        let decodedFrameCount = destination.withUnsafeMutableBufferPointer { outputBuffer in
            switch backend {
            case let .single(pointer):
                opus_decode_float(
                    pointer,
                    payload.bindMemory(to: UInt8.self).baseAddress,
                    Int32(payload.count),
                    outputBuffer.baseAddress!,
                    Int32(configuration.maximumSamplesPerChannel),
                    decodeFEC ? 1 : 0
                )
            case let .multistream(pointer):
                opus_multistream_decode_float(
                    pointer,
                    payload.bindMemory(to: UInt8.self).baseAddress,
                    Int32(payload.count),
                    outputBuffer.baseAddress!,
                    Int32(configuration.maximumSamplesPerChannel),
                    decodeFEC ? 1 : 0
                )
            }
        }

        if decodedFrameCount < 0 {
            throw SwiftOpus.OpusError(decodedFrameCount)
        }

        return Int(decodedFrameCount)
    }

    private func decodeInterleavedInt16Locked(
        payload: UnsafeRawBufferPointer,
        decodeFEC: Bool,
        into destination: inout [Int16]
    ) throws -> Int {
        guard payload.count > 0 else {
            return 0
        }
        guard payload.count <= Int(Int32.max) else {
            throw SwiftOpus.RuntimeError.invalidPacketSize(payload.count)
        }

        let decodedFrameCount = destination.withUnsafeMutableBufferPointer { outputBuffer in
            switch backend {
            case let .single(pointer):
                opus_decode(
                    pointer,
                    payload.bindMemory(to: UInt8.self).baseAddress,
                    Int32(payload.count),
                    outputBuffer.baseAddress!,
                    Int32(configuration.maximumSamplesPerChannel),
                    decodeFEC ? 1 : 0
                )
            case let .multistream(pointer):
                opus_multistream_decode(
                    pointer,
                    payload.bindMemory(to: UInt8.self).baseAddress,
                    Int32(payload.count),
                    outputBuffer.baseAddress!,
                    Int32(configuration.maximumSamplesPerChannel),
                    decodeFEC ? 1 : 0
                )
            }
        }

        if decodedFrameCount < 0 {
            throw SwiftOpus.OpusError(decodedFrameCount)
        }

        return Int(decodedFrameCount)
    }
}
