// swift-tools-version: 5.10
import PackageDescription

/// Concrete theme palettes (SwiftUI Color values), font registration helpers,
/// and the theme protocol shared UI components consume. Depends on KotiCore
/// for `ThemeKey` so we don't duplicate identifiers across packages.
let package = Package(
    name: "KotiThemes",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KotiThemes", targets: ["KotiThemes"])
    ],
    dependencies: [
        .package(path: "../KotiCore")
    ],
    targets: [
        .target(
            name: "KotiThemes",
            dependencies: ["KotiCore"],
            path: "Sources/KotiThemes"
        )
    ]
)
