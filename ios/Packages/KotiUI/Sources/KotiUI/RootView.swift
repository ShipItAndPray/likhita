import SwiftUI
import KotiCore
import KotiThemes
import KotiL10n

/// Top-level view both apps mount. Holds the active onboarding/writing
/// state machine and themes the rendering tree from the host's
/// `AppConfiguration`. v1 routes only between Sankalpam and Writing — past
/// kotis, settings, and ship flow are reachable from sub-views.
public struct RootView: View {
    private let config: any AppConfiguration

    @State private var route: Route

    public init(config: any AppConfiguration) {
        self.config = config
        // Cold start: if persistence has an active koti, jump straight in;
        // otherwise begin the sankalpam. Persistence wiring lands once
        // SwiftData container is owned by the app shell.
        _route = State(initialValue: .sankalpam(step: .identity))
    }

    public var body: some View {
        let theme = ThemeRegistry.theme(for: config.defaultThemeKey)
        ZStack {
            theme.surface.ignoresSafeArea()
            content
                .foregroundStyle(theme.textPrimary)
        }
        .environment(\.theme, theme)
        .environment(\.appConfig, AnyAppConfiguration(config))
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .sankalpam(let step):
            SankalpamView(step: step) { next in
                route = .sankalpam(step: next)
            } onComplete: {
                route = .writing
            }
        case .writing:
            WritingSurfaceView()
        case .completion:
            CompletionView()
        }
    }
}

extension RootView {
    enum Route: Equatable {
        case sankalpam(step: SankalpamView.Step)
        case writing
        case completion
    }
}
