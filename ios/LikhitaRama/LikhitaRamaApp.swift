import SwiftUI
import KotiUI

/// Entry point for the merged Likhita app (bundle `org.likhita.rama`,
/// display name "Likhita"). The previous per-target `RootView(config:
/// AppConfig.shared)` mount is replaced by `LikhitaShell`, which shows
/// the first-launch [[language-picker-view]] before any tradition-
/// specific routing.
@main
struct LikhitaRamaApp: App {
    var body: some Scene {
        WindowGroup {
            LikhitaShell { tradition in
                AppConfig.forTradition(tradition)
            }
        }
    }
}
