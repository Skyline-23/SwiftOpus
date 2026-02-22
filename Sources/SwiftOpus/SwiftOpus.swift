import AVFoundation
@_exported import COpus

public enum SwiftOpus: Sendable {}

public extension SwiftOpus {
    static let runtimeTagEnvironmentKey = "SWIFTOPUS_LIBOPUS_TAG"
    static let version = "0.1.0"
    static let bundledLibopusTag: SwiftOpusLibopusTag = .v1_6_1
    static let minimumSamplesPerChannelPerPacket: AVAudioFrameCount = 20
    static let maximumSamplesPerChannelPerPacket: AVAudioFrameCount = 5_760
    static let defaultMaximumPacketBytes = 1_500
    static let maximumRecommendedChannelCount = 8

    static var runtimeLibopusVersionString: String {
        if let override = ProcessInfo.processInfo.environment[runtimeTagEnvironmentKey],
           let tag = SwiftOpusLibopusTag(rawValue: override) {
            return tag.rawValue
        }
        return bundledLibopusTag.rawValue
    }

    static var compatibilityProfile: SwiftOpusCompatibilityProfile {
        SwiftOpusCompatibilityProfile.detect()
    }
}
