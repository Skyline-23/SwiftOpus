import Testing
@testable import SwiftOpus

@Test("Package loads COpus symbols")
func packageLoadsCOpusSymbols() {
    #expect(OPUS_OK == 0)
}
