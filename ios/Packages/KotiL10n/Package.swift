// swift-tools-version: 5.10
import PackageDescription

/// Centralized strings catalog (te / hi / en) so both apps share a single
/// translation file. Resources are picked up via `.process(...)` so Xcode
/// generates the symbol table automatically.
let package = Package(
    name: "KotiL10n",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KotiL10n", targets: ["KotiL10n"])
    ],
    targets: [
        .target(
            name: "KotiL10n",
            path: "Sources/KotiL10n",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
