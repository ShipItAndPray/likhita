import SwiftUI
import KotiUI

/// Entry point for the Telugu app (org.likhita.rama).
/// All routing/state lives in `RootView` inside KotiUI; this file
/// only injects the per-app `AppConfig` so the shared UI can skin itself.
@main
struct LikhitaRamaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(config: AppConfig.shared)
        }
    }
}
