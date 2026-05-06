import SwiftUI
import KotiUI

/// Entry point for the Hindi app (org.likhita.ram).
/// Mantra is `.ramOrSitaramSubchoice`; the user picks Ram vs Sitaram in
/// Sankalpam Step 0 (per spec §21 v1 scope).
@main
struct LikhitaRamApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(config: AppConfig.shared)
        }
    }
}
