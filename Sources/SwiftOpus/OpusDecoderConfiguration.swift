import AVFoundation
import Foundation

public struct OpusDecoderConfiguration: Sendable, Equatable {
    public let sampleRate: OpusSampleRate
    public let channels: Int
    public let pcmFormat: AVAudioFormat.SwiftOpusPCMCommonFormat
    public let maximumSamplesPerChannel: Int
    public let multistreamLayout: OpusChannelLayout?

    public init(
        sampleRate: OpusSampleRate,
        channels: Int,
        pcmFormat: AVAudioFormat.SwiftOpusPCMCommonFormat = .float32,
        maximumSamplesPerChannel: Int = Int(SwiftOpus.maximumSamplesPerChannelPerPacket),
        multistreamLayout: OpusChannelLayout? = nil
    ) throws {
        guard channels > 0 else {
            throw SwiftOpus.RuntimeError.unsupportedChannelCount(channels)
        }
        guard channels <= SwiftOpus.maximumRecommendedChannelCount else {
            throw SwiftOpus.RuntimeError.unsupportedChannelCount(channels)
        }
        guard maximumSamplesPerChannel >= Int(SwiftOpus.minimumSamplesPerChannelPerPacket),
              maximumSamplesPerChannel <= Int(SwiftOpus.maximumSamplesPerChannelPerPacket)
        else {
            throw SwiftOpus.RuntimeError.invalidFrameSize(maximumSamplesPerChannel)
        }

        if let multistreamLayout {
            guard multistreamLayout.channels == channels else {
                throw SwiftOpus.RuntimeError.invalidMultistreamLayout(
                    channels: channels,
                    streamCount: multistreamLayout.streamCount,
                    coupledStreamCount: multistreamLayout.coupledStreamCount,
                    mappingCount: multistreamLayout.mapping.count
                )
            }
        }

        self.sampleRate = sampleRate
        self.channels = channels
        self.pcmFormat = pcmFormat
        self.maximumSamplesPerChannel = maximumSamplesPerChannel
        self.multistreamLayout = multistreamLayout
    }

    public var usesMultistreamDecoder: Bool {
        if let multistreamLayout {
            return multistreamLayout.channels > 2
        }
        return channels > 2
    }

    public var avAudioFormat: AVAudioFormat {
        get throws {
            guard let format = AVAudioFormat(
                swiftOpusPCMFormat: pcmFormat,
                sampleRate: sampleRate,
                channels: AVAudioChannelCount(channels),
                interleaved: false
            ) else {
                throw SwiftOpus.RuntimeError.unsupportedPCMFormat("\(pcmFormat)")
            }
            return format
        }
    }

    public static func defaultLayout(forChannels channels: Int) throws -> OpusChannelLayout? {
        guard channels > 2 else {
            return nil
        }
        return try OpusChannelLayout.standardSurround(for: channels)
    }
}
