import AVFoundation

public extension AVAudioFormat {
    enum SwiftOpusPCMCommonFormat: Sendable {
        case int16
        case float32
    }

    convenience init?(
        swiftOpusPCMFormat: SwiftOpusPCMCommonFormat,
        sampleRate: OpusSampleRate,
        channels: AVAudioChannelCount,
        interleaved: Bool? = nil
    ) {
        guard channels > 0 else {
            return nil
        }

        if channels > 2 {
            guard let channelLayoutData = Self.swiftOpusChannelLayoutData(for: channels) else {
                return nil
            }
            switch swiftOpusPCMFormat {
            case .int16:
                self.init(settings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: sampleRate.asInt,
                    AVNumberOfChannelsKey: Int(channels),
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: true,
                    AVChannelLayoutKey: channelLayoutData,
                ])
            case .float32:
                self.init(settings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: sampleRate.asInt,
                    AVNumberOfChannelsKey: Int(channels),
                    AVLinearPCMBitDepthKey: 32,
                    AVLinearPCMIsFloatKey: true,
                    AVLinearPCMIsNonInterleaved: true,
                    AVChannelLayoutKey: channelLayoutData,
                ])
            }
            guard isSupportedBySwiftOpusRuntime else {
                return nil
            }
            return
        }

        let resolvedInterleaved = interleaved ?? (channels > 1)
        switch swiftOpusPCMFormat {
        case .int16:
            self.init(
                commonFormat: .pcmFormatInt16,
                sampleRate: sampleRate.asDouble,
                channels: channels,
                interleaved: resolvedInterleaved
            )
        case .float32:
            self.init(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate.asDouble,
                channels: channels,
                interleaved: resolvedInterleaved
            )
        }
        guard isSupportedBySwiftOpusRuntime else {
            return nil
        }
    }

    var isSupportedBySwiftOpusRuntime: Bool {
        guard OpusSampleRate(rawValue: Int32(sampleRate.rounded())) != nil else {
            return false
        }

        switch commonFormat {
        case .pcmFormatInt16, .pcmFormatFloat32:
            break
        default:
            return false
        }

        guard channelCount >= 1 else {
            return false
        }

        return channelCount <= AVAudioChannelCount(SwiftOpus.maximumRecommendedChannelCount)
    }

    var isSupportedBySwiftOpusEncoder: Bool {
        guard isSupportedBySwiftOpusRuntime else {
            return false
        }
        return channelCount == 1 || channelCount == 2
    }

    var isSupportedBySwiftOpusDecoder: Bool {
        isSupportedBySwiftOpusRuntime
    }

    private static func swiftOpusChannelLayoutData(for channels: AVAudioChannelCount) -> Data? {
        guard let channelLayout = AVAudioChannelLayout(
            layoutTag: swiftOpusChannelLayoutTag(for: channels)
        ) else {
            return nil
        }
        return Data(
            bytes: channelLayout.layout,
            count: MemoryLayout<AudioChannelLayout>.size
        )
    }

    private static func swiftOpusChannelLayoutTag(for channels: AVAudioChannelCount) -> AudioChannelLayoutTag {
        switch Int(channels) {
        case 1:
            return kAudioChannelLayoutTag_Mono
        case 2:
            return kAudioChannelLayoutTag_Stereo
        case 6:
            return kAudioChannelLayoutTag_MPEG_5_1_D
        case 8:
            return kAudioChannelLayoutTag_MPEG_7_1_C
        default:
            return kAudioChannelLayoutTag_DiscreteInOrder | AudioChannelLayoutTag(channels)
        }
    }
}
