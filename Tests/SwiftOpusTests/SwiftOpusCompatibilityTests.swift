import Testing
@testable import SwiftOpus

@Test("Semantic version parser handles prefixed libopus string")
func semanticVersionParserHandlesPrefixedLibopusString() {
    let parsed = SwiftOpusSemanticVersion(parsing: "libopus 1.5.2")

    #expect(parsed == .init(major: 1, minor: 5, patch: 2))
}

@Test("Libopus tags resolve from runtime semver")
func libopusTagsResolveFromRuntimeSemver() {
    let parsed = SwiftOpusSemanticVersion(parsing: "libopus 1.6.1")
    let tag = SwiftOpusLibopusTag.resolveNearestTag(for: parsed)

    #expect(tag == .v1_6_1)
}

@Test("Runtime libopus version string follows configured bundled tag")
func runtimeLibopusVersionStringFollowsConfiguredBundledTag() {
    #expect(SwiftOpus.runtimeLibopusVersionString == SwiftOpus.bundledLibopusTag.rawValue)
}

@Test("Compatibility profile resolves runtime tag policy")
func compatibilityProfileResolvesRuntimeTagPolicy() {
    let profile = SwiftOpusCompatibilityProfile.detect(
        runtimeLibopusVersionString: "libopus 1.5.2"
    )

    #expect(profile.resolvedRuntimeLibopusTag == .v1_5_2)
    #expect(profile.supportsInBandFEC)
    #expect(profile.supportsMultistreamLayout)
    #expect(profile.maximumRecommendedPacketBytes == 8_192)
}

@Test("Compatibility profile keeps conservative defaults when runtime tag is unknown")
func compatibilityProfileKeepsConservativeDefaultsWhenRuntimeTagUnknown() {
    let profile = SwiftOpusCompatibilityProfile.detect(
        runtimeLibopusVersionString: "unknown"
    )

    #expect(profile.resolvedRuntimeLibopusTag == nil)
    #expect(!profile.supportsMultistreamLayout)
    #expect(!profile.supportsInBandFEC)
    #expect(profile.maximumRecommendedPacketBytes == 1_500)
}
