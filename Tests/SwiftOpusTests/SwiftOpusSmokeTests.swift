import Testing
@testable import SwiftOpus

@Test("Opus constants expose expected frame bounds")
func opusConstantsExposeExpectedFrameBounds() {
    #expect(SwiftOpus.minimumSamplesPerChannelPerPacket == 20)
    #expect(SwiftOpus.maximumSamplesPerChannelPerPacket == 5_760)
}
