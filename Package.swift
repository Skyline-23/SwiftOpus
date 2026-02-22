// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftOpus",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "SwiftOpus", targets: ["SwiftOpus"]),
        .library(name: "COpusShim", targets: ["COpusShim"]),
    ],
    targets: [
        .target(
            name: "COpusShim",
            path: "Sources/COpusShim",
            publicHeadersPath: "include"
        ),
        .target(
            name: "SwiftOpus",
            dependencies: ["COpusShim"],
            path: "Sources/SwiftOpus"
        ),
        .testTarget(
            name: "SwiftOpusTests",
            dependencies: ["SwiftOpus"],
            path: "Tests/SwiftOpusTests"
        ),
    ]
)
