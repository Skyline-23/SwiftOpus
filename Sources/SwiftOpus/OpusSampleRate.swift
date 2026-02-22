public enum OpusSampleRate: Int32, CaseIterable, Sendable {
    case hz8k = 8_000
    case hz12k = 12_000
    case hz16k = 16_000
    case hz24k = 24_000
    case hz48k = 48_000

    public init?(exactly sampleRate: Int) {
        self.init(rawValue: Int32(sampleRate))
    }

    public var asDouble: Double { Double(rawValue) }
    public var asInt: Int { Int(rawValue) }
}
