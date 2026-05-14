import SwiftUI
import KotiCore

/// Top-level scene wrapper for the merged Likhita app. Decides between the
/// first-launch language picker and the rest of the experience based on
/// whether [[language-choice]] is set.
///
/// Replaces the old per-target shell where each app target mounted
/// `RootView(config: AppConfig.shared)` directly. After the 2026-05-14
/// merger ([[likhita-merger-decision]]) the tradition is chosen at
/// runtime by the picker, so this wrapper is the single place that owns
/// the choice → config mapping.
public struct LikhitaShell: View {
    /// Build-time configuration *factory*. Given the runtime tradition the
    /// user picked, returns the concrete `AppConfiguration` to mount. The
    /// target supplies this so we keep bundleId / apiBaseURL / app-origin
    /// in the target where they belong.
    public typealias ConfigFor = (PracticeTradition) -> any AppConfiguration

    private let configFor: ConfigFor

    @State private var choice: LanguageChoice?

    public init(configFor: @escaping ConfigFor) {
        self.configFor = configFor
        _choice = State(initialValue: LanguageChoiceStore.shared.current)
    }

    public var body: some View {
        Group {
            if let choice {
                RootView(config: configFor(choice.tradition))
            } else {
                LanguagePickerView { picked in
                    LanguageChoiceStore.shared.current = picked
                    withAnimation(.easeInOut(duration: 0.35)) {
                        choice = picked
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
