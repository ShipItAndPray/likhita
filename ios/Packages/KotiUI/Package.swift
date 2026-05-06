// swift-tools-version: 5.10
import PackageDescription

/// SwiftUI surface area shared between LikhitaRama and LikhitaRam. All views
/// take an `AppConfiguration` (from KotiCore) so the same View hierarchy
/// renders correctly regardless of which target hosts it.
let package = Package(
    name: "KotiUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KotiUI", targets: ["KotiUI"])
    ],
    dependencies: [
        .package(path: "../KotiCore"),
        .package(path: "../KotiThemes"),
        .package(path: "../KotiL10n")
    ],
    targets: [
        .target(
            name: "KotiUI",
            dependencies: [
                "KotiCore",
                "KotiThemes",
                "KotiL10n"
            ],
            path: "Sources/KotiUI"
        )
    ]
)
