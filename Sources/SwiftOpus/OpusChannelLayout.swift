import Foundation

public struct OpusChannelLayout: Equatable, Sendable {
    public let channels: Int
    public let streamCount: Int
    public let coupledStreamCount: Int
    public let mapping: [UInt8]

    public init(
        channels: Int,
        streamCount: Int,
        coupledStreamCount: Int,
        mapping: [UInt8]
    ) throws {
        guard channels > 0 else {
            throw SwiftOpus.RuntimeError.unsupportedChannelCount(channels)
        }
        guard streamCount > 0, coupledStreamCount >= 0, coupledStreamCount <= streamCount else {
            throw SwiftOpus.RuntimeError.invalidMultistreamLayout(
                channels: channels,
                streamCount: streamCount,
                coupledStreamCount: coupledStreamCount,
                mappingCount: mapping.count
            )
        }
        guard mapping.count == channels else {
            throw SwiftOpus.RuntimeError.invalidMultistreamLayout(
                channels: channels,
                streamCount: streamCount,
                coupledStreamCount: coupledStreamCount,
                mappingCount: mapping.count
            )
        }
        self.channels = channels
        self.streamCount = streamCount
        self.coupledStreamCount = coupledStreamCount
        self.mapping = mapping
    }

    public static func mono() throws -> Self {
        try .init(channels: 1, streamCount: 1, coupledStreamCount: 0, mapping: [0])
    }

    public static func stereo() throws -> Self {
        try .init(channels: 2, streamCount: 1, coupledStreamCount: 1, mapping: [0, 1])
    }

    public static func standardSurround(for channels: Int) throws -> Self {
        switch channels {
        case 1:
            return try mono()
        case 2:
            return try stereo()
        case 6:
            // RFC 7845 mapping family 1 (5.1)
            return try .init(channels: 6, streamCount: 4, coupledStreamCount: 2, mapping: [0, 4, 1, 2, 3, 5])
        case 8:
            // RFC 7845 mapping family 1 (7.1)
            return try .init(channels: 8, streamCount: 5, coupledStreamCount: 3, mapping: [0, 6, 1, 2, 3, 4, 5, 7])
        default:
            let normalizedChannels = max(1, channels)
            let mapping = (0..<normalizedChannels).map { UInt8($0 & 0xFF) }
            return try .init(
                channels: normalizedChannels,
                streamCount: normalizedChannels,
                coupledStreamCount: 0,
                mapping: mapping
            )
        }
    }
}
