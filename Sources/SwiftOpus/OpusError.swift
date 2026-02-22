import Foundation

public extension SwiftOpus {
    struct OpusError: Swift.Error, Equatable, RawRepresentable, ExpressibleByIntegerLiteral, Sendable, CustomStringConvertible {
        public typealias IntegerLiteralType = Int32
        public var rawValue: IntegerLiteralType

        public static let ok = Self(OPUS_OK)
        public static let badArgument = Self(OPUS_BAD_ARG)
        public static let bufferTooSmall = Self(OPUS_BUFFER_TOO_SMALL)
        public static let internalError = Self(OPUS_INTERNAL_ERROR)
        public static let invalidPacket = Self(OPUS_INVALID_PACKET)
        public static let unimplemented = Self(OPUS_UNIMPLEMENTED)
        public static let invalidState = Self(OPUS_INVALID_STATE)
        public static let allocationFailure = Self(OPUS_ALLOC_FAIL)

        public init(rawValue: IntegerLiteralType) {
            self.rawValue = rawValue
        }

        public init(integerLiteral value: IntegerLiteralType) {
            self.init(rawValue: value)
        }

        public init<T: BinaryInteger>(_ value: T) {
            self.init(rawValue: IntegerLiteralType(value))
        }

        public var isOK: Bool {
            rawValue == Self.ok.rawValue
        }

        public var description: String {
            guard let cString = opus_strerror(rawValue) else {
                return "Opus error \(rawValue)"
            }
            return String(cString: cString)
        }
    }

    enum RuntimeError: Swift.Error, Equatable, Sendable {
        case unsupportedSampleRate(Int)
        case unsupportedChannelCount(Int)
        case unsupportedPCMFormat(String)
        case allocationFailed
        case bufferTooSmall(expectedMinimum: Int, actual: Int)
        case invalidPacketSize(Int)
        case invalidFrameSize(Int)
        case invalidMultistreamLayout(channels: Int, streamCount: Int, coupledStreamCount: Int, mappingCount: Int)
    }

    static func throwOnOpusError(_ code: Int32) throws {
        let error = OpusError(code)
        if !error.isOK {
            throw error
        }
    }
}
