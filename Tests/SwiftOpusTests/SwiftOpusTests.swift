import Testing
@testable import SwiftOpus

@Test("SwiftOpus shim version is available")
func shimVersionIsAvailable() {
    #expect(SwiftOpus.shimVersion == 1)
}
