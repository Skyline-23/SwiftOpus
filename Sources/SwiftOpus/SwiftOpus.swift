import AVFoundation
@_exported import COpus

public enum SwiftOpus: Sendable {}

public extension SwiftOpus {
    static let minimumSamplesPerChannelPerPacket: AVAudioFrameCount = 20
    static let maximumSamplesPerChannelPerPacket: AVAudioFrameCount = 5_760
    static let defaultMaximumPacketBytes = 1_500
    static let maximumRecommendedChannelCount = 8
}
