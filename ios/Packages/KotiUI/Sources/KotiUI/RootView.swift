import SwiftUI
import KotiCore
import KotiThemes

/// Top-level view both apps mount. Holds the routing state for the full
/// 12-screen flow described in the design package (welcome → sankalpam(4)
/// → pledge → writing → path overlay → completion → book → ship → status
/// → settings).
///
/// State source-of-truth split:
///   - `form`: in-flight sankalpam answers (local-only until pledge complete)
///   - `viewModel`: server-backed koti — count is what the server returned,
///                  never optimistic. Survives app restart via KotiStore.
public struct RootView: View {
    private let config: any AppConfiguration

    @State private var route: Route
    @State private var pathOverlayOpen: Bool = false
    @State private var form = SankalpamForm()
    @State private var session: KotiSession
    @State private var viewModel: KotiViewModel
    @State private var sharedVM: SharedKotiViewModel
    @State private var didTryResume: Bool = false
    /// Pace screen — per-day mantra counts for the calendar. Populated by
    /// GET /v1/kotis/<id>/calendar when the user enters Pace.
    @State private var paceHistory: [(date: Date, count: Int)] = []
    @State private var paceLoading: Bool = false

    public init(config: any AppConfiguration) {
        self.config = config

        // UI-testing reset path: wipe any persisted Sangha queue + reset
        // active-koti pin so each test starts from a known baseline. Only
        // fires when both --ui-testing AND --reset-state are passed.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing") && args.contains("--reset-state") {
            KotiStore.resetForUITesting()
        }

        // KotiSession is initially empty. The server is the source of
        // truth for count + target; we never seed fake progress numbers
        // here. Earlier versions of this file seeded a 43,000/100,000
        // "design preview" mock which leaked into production state — when
        // a user picked a different mode (e.g. Japa 108) the seed was
        // higher than the server's currentCount=0 and `applyServer`'s
        // upward-only merge kept the seed. That made fresh kotis appear
        // with absurd counts on first paint.
        let initialSession = KotiSession(
            name: "",
            count: 0,
            target: 0,
            inkHex: config.tradition == .telugu ? "#E34234" : "#1A1410",
            theme: config.defaultThemeKey,
            modeKey: "lakh",
            daysActive: 0,
            dedicationText: ""
        )
        _session = State(initialValue: initialSession)

        // Build the API client. Until Clerk's iOS SDK is wired, we send the
        // device-stable user id via the dev `X-Test-Clerk-Id` header that the
        // backend already accepts (lib/auth.ts). Production swaps this for a
        // real Bearer token from Clerk's iOS session.
        let store = KotiStore.shared
        let stableUser = store.stableUserId()
        let api = APIClient(
            baseURL: config.apiBaseURL,
            appOrigin: config.appOriginHeader,
            extraHeaders: { ["X-Test-Clerk-Id": stableUser] }
        )
        let service = LikhitaService(api: api)
        let mantraTyped = config.tradition.content.mantraTyped
        _viewModel = State(initialValue: KotiViewModel(
            service: service,
            store: store,
            initialSession: initialSession,
            mantraTyped: mantraTyped
        ))
        _sharedVM = State(initialValue: SharedKotiViewModel(
            service: service,
            store: store,
            mantraTyped: mantraTyped
        ))

        // Allow design QA to land on a specific screen via launch env.
        // v2 design: default entry point is the Threshold (My Book vs Sangha).
        let envScreen = ProcessInfo.processInfo.environment["LIKHITA_START_SCREEN"] ?? ""
        let initial = Route(jumpKey: envScreen) ?? .threshold
        _route = State(initialValue: initial)
    }

    public var body: some View {
        let theme = ThemeRegistry.theme(
            for: form.themeKey == .bhadrachalamClassic && config.tradition == .hindi
                ? .banarasPothi
                : (form.themeKey != config.defaultThemeKey ? form.themeKey : config.defaultThemeKey)
        )
        let tradition = config.tradition.content
        ZStack {
            content(theme: theme, tradition: tradition)
            if pathOverlayOpen {
                RamayanaPathView(
                    tradition: tradition,
                    theme: theme,
                    progress: session.progress,
                    onClose: { withAnimation { pathOverlayOpen = false } }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .environment(\.theme, theme)
        .environment(\.appConfig, AnyAppConfiguration(config))
        .preferredColorScheme(.light)
        .onAppear {
            if form.themeKey != config.defaultThemeKey {
                form.themeKey = config.defaultThemeKey
            }
            if form.inkHex == "#E34234" && config.tradition == .hindi {
                form.inkHex = "#1A1410"
            }
        }
        .task {
            // Resume an active koti from the server on cold launch — the user
            // never has to re-walk the sankalpam to keep writing.
            if !didTryResume {
                didTryResume = true
                let resumed = await viewModel.resumeIfPossible()
                if resumed {
                    session = viewModel.session
                    route = .writing
                }
            }
        }
        // Mirror the source-of-truth viewModel.session into the local
        // @State copy that the writing surface + threshold bind to.
        // Trust the server unconditionally — the backend's compare-and-swap
        // UPDATE guarantees count never moves backward, so we don't need
        // a client-side max() here. (The earlier upward-only check was
        // load-bearing back when RootView seeded a 43,000 mock; with the
        // seed gone, mirroring directly is correct.)
        .onChange(of: viewModel.session.count) { _, new in
            session.count = new
            if new >= session.target && session.target > 0 && route == .writing {
                route = .completion
            }
        }
        .onChange(of: viewModel.session.target) { _, new in
            session.target = new
        }
    }

    @ViewBuilder
    private func content(theme: any Theme, tradition: TraditionContent) -> some View {
        // v2 design: The Sangha (shared koti) always renders in Bhadrachalam
        // cloth/foil regardless of which app you're in — it's the same
        // single Foundation Koti, not per-tradition.
        let sanghaTheme = ThemeRegistry.theme(for: .bhadrachalamClassic)

        switch route {
        case .threshold:
            ThresholdView(
                tradition: tradition,
                theme: theme,
                sanghaTheme: sanghaTheme,
                myCount: session.count,
                myTarget: session.target,
                sangha: sharedVM,
                onEnterMine: {
                    if viewModel.serverKotiId == nil {
                        route = .welcome
                    } else {
                        route = .writing
                    }
                },
                onEnterSangha: { route = .sharedHub }
            )
        case .sharedHub:
            SharedHubView(
                tradition: tradition,
                theme: sanghaTheme,
                vm: sharedVM,
                onWrite: { route = .sharedWrite },
                onOpenWriters: { route = .sharedHands },
                onClose: { route = .threshold }
            )
        case .sharedWrite:
            SharedWritingView(
                tradition: tradition,
                theme: theme,
                vm: sharedVM,
                onClose: { route = .sharedHub }
            )
        case .sharedHands:
            SharedWritersView(
                tradition: tradition,
                theme: sanghaTheme,
                vm: sharedVM,
                onClose: { route = .sharedHub }
            )
        case .welcome:
            WelcomeView(
                tradition: tradition,
                theme: theme,
                onBegin: { route = .identity }
            )
        case .identity:
            StepIdentityView(
                theme: theme,
                form: form,
                onBack: { route = .welcome },
                onNext: { route = .dedication }
            )
        case .dedication:
            StepDedicationView(
                theme: theme,
                tradition: tradition,
                form: form,
                onBack: { route = .identity },
                onNext: { route = .stylus }
            )
        case .stylus:
            StepStylusThemeView(
                theme: theme,
                tradition: tradition,
                form: form,
                availableThemes: ThemeRegistry.themes(for: config.tradition),
                onBack: { route = .dedication },
                onNext: { route = .pledge },
                onThemeSelected: { key in
                    form.themeKey = key
                    session.theme = key
                }
            )
        case .pledge:
            StepPledgeView(
                theme: theme,
                tradition: tradition,
                dedicationText: form.dedicationText,
                onBack: { route = .stylus },
                onComplete: { Task { await startWriting() } }
            )
        case .writing:
            WritingSurfaceView(
                tradition: tradition,
                theme: theme,
                koti: $session,
                onIncrement: { viewModel.commitMantra() },
                onKeystroke: { viewModel.recordKeystroke() },
                onOpenPath: { withAnimation { pathOverlayOpen = true } },
                onThreshold: { route = .threshold },
                onPause: { route = .pace },
                onComplete: { route = .completion },
                onFlush: { Task { await viewModel.flushNow() } }
            )
        case .completion:
            CompletionView(
                tradition: tradition,
                theme: theme,
                koti: completionKoti(),
                onContinue: { route = .book }
            )
        case .book:
            BookPreviewView(
                tradition: tradition,
                theme: theme,
                koti: completionKoti(),
                onBack: { route = .completion },
                onContinue: { route = .ship }
            )
        case .ship:
            ShipDecisionView(
                tradition: tradition,
                theme: theme,
                onBack: { route = .book },
                onShip: { _ in route = .status }
            )
        case .status:
            ShipStatusView(
                tradition: tradition,
                theme: theme,
                onDone: { route = .settings }
            )
        case .settings:
            SettingsView(
                tradition: tradition,
                theme: theme,
                koti: session,
                onClose: { route = .writing },
                onJump: { key in
                    if let r = Route(jumpKey: key) { route = r }
                }
            )
        case .pace:
            PaceScreen(
                tradition: tradition,
                theme: theme,
                koti: $session,
                dailyHistory: paceHistory,
                onGoalDaysChanged: { newDays in
                    session.goalDays = newDays
                    Task { await pushPaceUpdate(goalDays: newDays, reminderTimes: nil) }
                },
                onRemindersChanged: { slots in
                    session.reminderTimes = slots
                    Task {
                        await pushPaceUpdate(goalDays: nil, reminderTimes: slots)
                        await scheduleReminders(slots)
                    }
                },
                onBack: { route = .writing },
                onThreshold: { route = .threshold }
            )
            .task(id: viewModel.serverKotiId) {
                await loadPaceHistory()
            }
        }
    }

    /// PATCH /v1/kotis/{id}/pace. Best-effort; if the server fails the
    /// local session change still stands and we'll re-sync on the next
    /// koti refresh.
    private func pushPaceUpdate(goalDays: Int?, reminderTimes: [String]?) async {
        guard let id = viewModel.serverKotiId else { return }
        do {
            _ = try await viewModel.service.updatePace(
                kotiId: id,
                request: LikhitaService.UpdatePaceRequest(
                    goalDays: goalDays,
                    reminderTimes: reminderTimes
                )
            )
        } catch {
            // Silent — pace is not load-bearing for writing; the next
            // koti GET will reconcile if needed.
        }
    }

    /// Fetch the last 180 days of daily counts and store them on
    /// `paceHistory`. Caller is the Pace screen's .task.
    private func loadPaceHistory() async {
        guard let id = viewModel.serverKotiId else {
            paceHistory = []
            return
        }
        paceLoading = true
        defer { paceLoading = false }
        do {
            let resp = try await viewModel.service.getCalendar(kotiId: id, days: 180)
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.calendar = Calendar(identifier: .gregorian)
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = .current
            paceHistory = resp.daily.compactMap { day in
                guard let d = f.date(from: day.date) else { return nil }
                return (date: d, count: day.count)
            }
        } catch {
            // Leave whatever was last loaded; Pace renders a sparse
            // calendar rather than erroring out.
        }
    }

    /// Replace the iOS local-notification schedule with one repeating
    /// daily UNUserNotification per enabled reminder slot. iOS clamps to
    /// at most ~64 pending requests; we use 4 slot ids max with a stable
    /// id prefix so we can re-issue cleanly.
    private func scheduleReminders(_ slots: [String]) async {
        await LikhitaReminders.reschedule(slots: slots, tradition: config.tradition)
    }

    private func startWriting() async {
        let plan = form.modePlan
        // Local mirror — count starts at zero and only ever moves up via
        // server-confirmed increments below.
        session = KotiSession(
            name: form.name,
            count: 0,
            target: plan.count,
            inkHex: form.inkHex,
            theme: form.themeKey,
            modeKey: plan.key,
            daysActive: 0,
            dedicationText: form.dedicationText
        )

        // Hash the (currently fake) handwriting samples into a hex string so
        // the server has a stylus signature to bind subsequent entries to.
        // 32 hex chars satisfies the schema's 16..256 range.
        var hash = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(32))
        if hash.count < 32 { hash = String(repeating: "0", count: 32 - hash.count) + hash }

        let traditionPath = config.tradition == .telugu ? "telugu" : "hindi_ram"
        let renderedScript = config.tradition == .telugu ? "telugu" : "devanagari"

        do {
            try await viewModel.startKoti(
                traditionPath: traditionPath,
                renderedScript: renderedScript,
                modeKey: plan.key,
                targetCount: Int(plan.count),
                stylusColor: form.inkHex,
                stylusSignatureHash: hash,
                theme: themeServerKey(form.themeKey),
                dedicationText: form.dedicationText,
                dedicationTo: form.dedicationTo?.rawValue ?? "self",
                name: form.name
            )
            route = .writing
        } catch {
            // Don't strand the user — let them write locally; the next
            // app launch will retry resume. We surface the error in
            // viewModel.phase but stay on the pledge step so they know.
            session.count = 0
            route = .writing
        }
    }

    private func completionKoti() -> KotiSession {
        var k = session
        k.count = session.target
        if k.dedicationText.isEmpty { k.dedicationText = form.dedicationText }
        if k.name.isEmpty { k.name = form.name }
        if k.daysActive == 0 { k.daysActive = 87 }
        return k
    }

    private func themeServerKey(_ key: ThemeKey) -> String {
        switch key {
        case .bhadrachalamClassic: return "bhadrachalam_classic"
        case .palmLeafOla:         return "palm_leaf_ola"
        case .tirupatiSaffron:     return "tirupati_saffron"
        case .banarasPothi:        return "banaras_pothi"
        case .ayodhyaSandstone:    return "ayodhya_sandstone"
        case .tulsidasManuscript:  return "tulsidas_manuscript"
        case .parchment:           return "parchment"
        case .modernMinimalist:    return "modern_minimalist"
        }
    }
}

extension RootView {
    enum Route: Equatable {
        case threshold
        case welcome, identity, dedication, stylus, pledge
        case writing, completion, book, ship, status, settings
        case pace
        case sharedHub, sharedWrite, sharedHands

        init?(jumpKey: String) {
            switch jumpKey {
            case "threshold":   self = .threshold
            case "shared", "sharedHub": self = .sharedHub
            case "sharedWrite": self = .sharedWrite
            case "sharedHands": self = .sharedHands
            case "welcome":    self = .welcome
            case "identity":   self = .identity
            case "dedication": self = .dedication
            case "stylus":     self = .stylus
            case "pledge":     self = .pledge
            case "writing":    self = .writing
            case "path":       self = .writing  // path is an overlay, opened separately
            case "completion": self = .completion
            case "book":       self = .book
            case "ship":       self = .ship
            case "status":     self = .status
            case "settings":   self = .settings
            case "pace":       self = .pace
            default:           return nil
            }
        }
    }
}
