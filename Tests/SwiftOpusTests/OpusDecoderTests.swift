import AVFoundation
import Testing
@testable import SwiftOpus

@Test("Package loads COpus symbols")
func packageLoadsCOpusSymbols() {
    #expect(OPUS_OK == 0)
}

@Test("Standard surround layout for 5.1 matches RFC mapping")
func standardSurroundLayoutForFiveOneMatchesExpectedMapping() throws {
    let layout = try OpusChannelLayout.standardSurround(for: 6)

    #expect(layout.channels == 6)
    #expect(layout.streamCount == 4)
    #expect(layout.coupledStreamCount == 2)
    #expect(layout.mapping == [0, 4, 1, 2, 3, 5])
}

@Test("Stereo decoder configuration builds non-interleaved output format")
func stereoDecoderConfigurationBuildsOutputFormat() throws {
    let configuration = try OpusDecoderConfiguration(
        sampleRate: .hz48k,
        channels: 2,
        pcmFormat: .float32
    )
    let decoder = try OpusDecoder(configuration: configuration)

    #expect(decoder.outputFormat.channelCount == 2)
    #expect(decoder.outputFormat.commonFormat == .pcmFormatFloat32)
    #expect(decoder.outputFormat.isInterleaved == false)
}

@Test("Multistream decoder initializes for 5.1")
func multistreamDecoderInitializesForFiveOne() throws {
    let layout = try OpusChannelLayout.standardSurround(for: 6)
    let configuration = try OpusDecoderConfiguration(
        sampleRate: .hz48k,
        channels: 6,
        pcmFormat: .float32,
        multistreamLayout: layout
    )

    let decoder = try OpusDecoder(configuration: configuration)

    #expect(decoder.outputFormat.channelCount == 6)
}

@Test("Decode reports buffer-too-small when interleaved destination is undersized")
func decodeReportsBufferTooSmallForUndersizedDestination() throws {
    let configuration = try OpusDecoderConfiguration(
        sampleRate: .hz48k,
        channels: 2,
        pcmFormat: .float32
    )
    let decoder = try OpusDecoder(configuration: configuration)
    var destination = [Float](repeating: 0, count: 16)

    var didThrow = false
    do {
        try destination.withUnsafeMutableBufferPointer { buffer in
            _ = try decoder.decodeInterleavedFloat(
                payload: Data([0x00, 0x01, 0x02, 0x03]),
                into: buffer
            )
        }
    } catch let error as SwiftOpus.RuntimeError {
        didThrow = true
        if case let .bufferTooSmall(expectedMinimum, actual) = error {
            #expect(expectedMinimum > actual)
        } else {
            Issue.record("Unexpected runtime error: \(error)")
        }
    }

    #expect(didThrow)
}

@Test("decodeToPCMBuffer returns nil for empty payload")
func decodeToPCMBufferReturnsNilForEmptyPayload() throws {
    let configuration = try OpusDecoderConfiguration(
        sampleRate: .hz48k,
        channels: 2,
        pcmFormat: .float32
    )
    let decoder = try OpusDecoder(configuration: configuration)

    let decoded = try decoder.decodeToPCMBuffer(payload: Data())

    #expect(decoded == nil)
}
