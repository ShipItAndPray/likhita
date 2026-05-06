// swift-tools-version: 5.10
import PackageDescription

/// Pure Swift core: domain models, networking, anti-cheat, stylus math,
/// and SwiftData persistence. No SwiftUI imports — depends only on
/// Foundation and SwiftData (iOS 17+).
let package = Package(
    name: "KotiCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KotiCore", targets: ["KotiCore"])
    ],
    targets: [
        .target(
            name: "KotiCore",
            path: "Sources/KotiCore"
        ),
        .testTarget(
            name: "KotiCoreTests",
            dependencies: ["KotiCore"],
            path: "Tests/KotiCoreTests"
        )
    ]
)
