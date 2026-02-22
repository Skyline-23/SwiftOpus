import Foundation

public enum SwiftOpusLibopusTag: String, Sendable, CaseIterable, Comparable {
    case v0_9_4 = "v0.9.4"
    case v0_9_5 = "v0.9.5"
    case v0_9_6 = "v0.9.6"
    case v0_9_7 = "v0.9.7"
    case v0_9_8 = "v0.9.8"
    case v0_9_9 = "v0.9.9"
    case v0_9_10 = "v0.9.10"
    case v0_9_11 = "v0.9.11"
    case v0_9_14 = "v0.9.14"
    case v1_0_0 = "v1.0.0"
    case v1_0_1 = "v1.0.1"
    case v1_0_2 = "v1.0.2"
    case v1_0_3 = "v1.0.3"
    case v1_1 = "v1.1"
    case v1_1_1 = "v1.1.1"
    case v1_1_2 = "v1.1.2"
    case v1_1_3 = "v1.1.3"
    case v1_1_4 = "v1.1.4"
    case v1_1_5 = "v1.1.5"
    case v1_2 = "v1.2"
    case v1_2_1 = "v1.2.1"
    case v1_3 = "v1.3"
    case v1_3_1 = "v1.3.1"
    case v1_4 = "v1.4"
    case v1_5 = "v1.5"
    case v1_5_1 = "v1.5.1"
    case v1_5_2 = "v1.5.2"
    case v1_6 = "v1.6"
    case v1_6_1 = "v1.6.1"

    public var semanticVersion: SwiftOpusSemanticVersion {
        SwiftOpusSemanticVersion(parsing: rawValue) ?? .init(major: 0, minor: 0, patch: 0)
    }

    public static func resolveNearestTag(for semanticVersion: SwiftOpusSemanticVersion?) -> Self? {
        guard let semanticVersion else {
            return nil
        }
        return allCases
            .sorted { $0.semanticVersion < $1.semanticVersion }
            .last { $0.semanticVersion <= semanticVersion }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.semanticVersion < rhs.semanticVersion
    }
}

public struct SwiftOpusSemanticVersion: Sendable, Equatable, Comparable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = max(0, major)
        self.minor = max(0, minor)
        self.patch = max(0, patch)
    }

    public init?(parsing rawValue: String) {
        let digitOrDot = rawValue.map { character -> Character in
            if character.isNumber || character == "." {
                return character
            }
            return " "
        }
        let tokens = String(digitOrDot)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard let candidate = tokens.first else {
            return nil
        }

        let parts = candidate
            .split(separator: ".", omittingEmptySubsequences: false)
            .compactMap { Int($0) }
        guard !parts.isEmpty else {
            return nil
        }

        self.init(
            major: parts[safe: 0] ?? 0,
            minor: parts[safe: 1] ?? 0,
            patch: parts[safe: 2] ?? 0
        )
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

public struct SwiftOpusCompatibilityProfile: Sendable, Equatable {
    public let resolvedRuntimeLibopusTag: SwiftOpusLibopusTag?
    public let minimumRuntimeLibopusTagForFEC: SwiftOpusLibopusTag
    public let minimumRuntimeLibopusTagForMultistream: SwiftOpusLibopusTag
    public let runtimeLibopusVersionString: String
    public let runtimeLibopusVersion: SwiftOpusSemanticVersion?
    public let supportsInBandFEC: Bool
    public let supportsMultistreamLayout: Bool
    public let maximumRecommendedPacketBytes: Int

    public init(
        resolvedRuntimeLibopusTag: SwiftOpusLibopusTag?,
        minimumRuntimeLibopusTagForFEC: SwiftOpusLibopusTag,
        minimumRuntimeLibopusTagForMultistream: SwiftOpusLibopusTag,
        runtimeLibopusVersionString: String,
        runtimeLibopusVersion: SwiftOpusSemanticVersion?,
        supportsInBandFEC: Bool,
        supportsMultistreamLayout: Bool,
        maximumRecommendedPacketBytes: Int
    ) {
        self.resolvedRuntimeLibopusTag = resolvedRuntimeLibopusTag
        self.minimumRuntimeLibopusTagForFEC = minimumRuntimeLibopusTagForFEC
        self.minimumRuntimeLibopusTagForMultistream = minimumRuntimeLibopusTagForMultistream
        self.runtimeLibopusVersionString = runtimeLibopusVersionString
        self.runtimeLibopusVersion = runtimeLibopusVersion
        self.supportsInBandFEC = supportsInBandFEC
        self.supportsMultistreamLayout = supportsMultistreamLayout
        self.maximumRecommendedPacketBytes = max(512, maximumRecommendedPacketBytes)
    }

    public func supportsSurroundDecoding(channelCount: Int) -> Bool {
        supportsMultistreamLayout && channelCount > 2
    }

    public static func detect(
        runtimeLibopusVersionString: String = SwiftOpus.runtimeLibopusVersionString
    ) -> Self {
        let runtimeVersion = SwiftOpusSemanticVersion(parsing: runtimeLibopusVersionString)
        let runtimeTag = SwiftOpusLibopusTag.resolveNearestTag(for: runtimeVersion)

        let minimumRuntimeLibopusTagForFEC: SwiftOpusLibopusTag = .v1_1
        let minimumRuntimeLibopusTagForMultistream: SwiftOpusLibopusTag = .v1_0_0

        let supportsMultistreamLayout: Bool
        if let runtimeTag {
            supportsMultistreamLayout = runtimeTag >= minimumRuntimeLibopusTagForMultistream
        } else {
            supportsMultistreamLayout = false
        }

        let supportsInBandFEC: Bool
        if let runtimeTag {
            supportsInBandFEC = runtimeTag >= minimumRuntimeLibopusTagForFEC
        } else {
            supportsInBandFEC = false
        }

        let maximumRecommendedPacketBytes = recommendedPacketLimit(runtimeTag: runtimeTag)

        return .init(
            resolvedRuntimeLibopusTag: runtimeTag,
            minimumRuntimeLibopusTagForFEC: minimumRuntimeLibopusTagForFEC,
            minimumRuntimeLibopusTagForMultistream: minimumRuntimeLibopusTagForMultistream,
            runtimeLibopusVersionString: runtimeLibopusVersionString,
            runtimeLibopusVersion: runtimeVersion,
            supportsInBandFEC: supportsInBandFEC,
            supportsMultistreamLayout: supportsMultistreamLayout,
            maximumRecommendedPacketBytes: maximumRecommendedPacketBytes
        )
    }

    private static func recommendedPacketLimit(
        runtimeTag: SwiftOpusLibopusTag?
    ) -> Int {
        guard let runtimeTag else {
            return 1_500
        }
        if runtimeTag >= .v1_5 {
            return 8_192
        }
        if runtimeTag >= .v1_1 {
            return 4_096
        }
        return 1_500
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
