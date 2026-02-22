import Foundation
import COpusShim

public enum SwiftOpus {
    public static var shimVersion: Int {
        Int(swiftopus_shim_version())
    }
}
