import SwiftUI
import KotiCore
import KotiThemes
import Combine

/// Pace — the rhythm. Lives inside My Book, reached from the writing surface.
///
/// Shows the user their pledged target distributed across a chosen number of
/// days, today's measure, a heat-map calendar over the last 30 days
/// (paginated back 30-day windows), and four optional reminder slots
/// (at most three enabled at once). All persistence is delegated to the
/// caller via `onGoalDaysChanged` and `onRemindersChanged`.
///
/// Mirrors `/tmp/likhita-design-v3/ramakoti/project/pace.jsx`.
public struct PaceScreen: View {
    let tradition: TraditionContent
    let theme: any Theme
    @Binding var koti: KotiSession
    /// Daily history as `YYYY-MM-DD` → count, from the server's `GET /calendar`.
    /// Expected oldest → newest; the screen tolerates either order.
    let dailyHistory: [(date: Date, count: Int)]
    /// Fired when the user drags the slider, debounced by 400ms — caller
    /// is expected to `PATCH /pace` with the new value.
    let onGoalDaysChanged: (Int) -> Void
    /// Fired when the user toggles a reminder slot. Caller `PATCH /pace`.
    let onRemindersChanged: ([String]) -> Void
    let onBack: () -> Void
    let onThreshold: () -> Void

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        koti: Binding<KotiSession>,
        dailyHistory: [(date: Date, count: Int)],
        onGoalDaysChanged: @escaping (Int) -> Void,
        onRemindersChanged: @escaping ([String]) -> Void,
        onBack: @escaping () -> Void,
        onThreshold: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self._koti = koti
        self.dailyHistory = dailyHistory
        self.onGoalDaysChanged = onGoalDaysChanged
        self.onRemindersChanged = onRemindersChanged
        self.onBack = onBack
        self.onThreshold = onThreshold
    }

    // MARK: - Goal-slider debounce
    @State private var pendingGoalDays: Int?
    @State private var goalDebounceTask: Task<Void, Never>?

    // MARK: - Computed pace metrics

    /// Normalises whatever order the caller supplies into oldest→newest.
    private var history: [(date: Date, count: Int)] {
        dailyHistory.sorted { $0.date < $1.date }
    }

    private var remaining: Int64 { max(0, koti.target - koti.count) }

    /// Days elapsed in the practice. Prefer the count of non-zero days in
    /// `dailyHistory`; fall back to `koti.daysActive` when history is empty.
    private var daysIn: Int {
        let active = history.reduce(0) { $1.count > 0 ? $0 + 1 : $0 }
        return active > 0 ? active : koti.daysActive
    }

    private var daysRemaining: Int { max(0, koti.goalDays - daysIn) }

    /// Mantras needed per remaining day to hit the original target.
    private var todayTarget: Int {
        Int(ceil(Double(remaining) / Double(max(1, daysRemaining))))
    }

    /// Today's count from the calendar history (0 if today not present).
    private var todayDone: Int {
        let cal = Calendar.current
        let today = Date()
        return history.first { cal.isDate($0.date, inSameDayAs: today) }?.count ?? 0
    }

    private var todayPct: Double {
        min(1.0, Double(todayDone) / Double(max(1, todayTarget)))
    }

    private var avgPerDay: Int {
        Int(Double(koti.count) / Double(max(1, daysIn)))
    }

    /// At the user's current average, how many more days would completion take.
    private var projectedDays: Int {
        Int(ceil(Double(remaining) / Double(max(1, avgPerDay))))
    }

    private var onTrack: Bool { projectedDays <= daysRemaining }
    private var drift: Int { abs(projectedDays - daysRemaining) }

    /// Consecutive days from today (working backwards) with `count > 0`.
    private var streak: Int {
        let cal = Calendar.current
        var s = 0
        var cursor = Date()
        // Reverse map by start-of-day for cheap lookups.
        var lookup: [Date: Int] = [:]
        for entry in history {
            lookup[cal.startOfDay(for: entry.date)] = entry.count
        }
        while let count = lookup[cal.startOfDay(for: cursor)], count > 0 {
            s += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return s
    }

    private var maxInHistory: Int { max(history.map(\.count).max() ?? 1, 1) }

    // MARK: - Body

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        vowLine
                        todayBlock
                            .padding(.top, 18)
                        goalSlider
                            .padding(.top, 16)
                        calendarBlock
                            .padding(.top, 22)
                        remindersBlock
                            .padding(.top, 22)
                        footerNote
                            .padding(.top, 18)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
        }
        .foregroundStyle(theme.textPrimary)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Text("‹")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("PACE · THE RHYTHM")
                .font(.system(size: 11))
                .kerning(2)
                .foregroundStyle(theme.textPrimary.opacity(0.55))
            Spacer()
            ThresholdPill(
                color: theme.textPrimary,
                background: Color.white.opacity(0.6),
                label: "↩",
                action: onThreshold
            )
        }
        .padding(.horizontal, 22)
        .padding(.top, 54)
        .padding(.bottom, 6)
    }

    // MARK: - Vow line

    private var vowLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            (
                Text(formattedIN(koti.target) + " mantras")
                    .font(.custom("EB Garamond", size: 22))
                +
                Text(" · over \(koti.goalDays) days")
                    .font(.custom("EB Garamond", size: 14))
                    .italic()
                    .foregroundColor(theme.textPrimary.opacity(0.55))
            )
            .lineSpacing(4)
            Text("Day \(daysIn) of \(koti.goalDays) · \(daysRemaining) remain")
                .font(.custom("EB Garamond", size: 12))
                .italic()
                .foregroundStyle(theme.textPrimary.opacity(0.6))
            GoldRule(foil: theme.foil, width: 300)
                .padding(.top, 10)
        }
    }

    // MARK: - Today block

    private var todayBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("TODAY'S MEASURE")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Text(dateLabel(Date(), format: "EEEE, MMM d"))
                    .font(.system(size: 10).monospacedDigit())
                    .kerning(1.2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(todayDone)")
                    .font(.custom("EB Garamond", size: 38))
                    .kerning(0.4)
                    .foregroundStyle(theme.textPrimary)
                Text("/ \(todayTarget)")
                    .font(.custom("EB Garamond", size: 18))
                    .foregroundStyle(theme.textPrimary.opacity(0.5))
                Spacer()
                paceStatusPill
            }
            .padding(.top, 8)

            // Progress bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.06))
                    .frame(height: 5)
                GeometryReader { g in
                    Capsule()
                        .fill(koti.inkColor)
                        .frame(width: max(0, g.size.width * todayPct), height: 5)
                        .animation(.easeOut(duration: 0.5), value: todayPct)
                }
                .frame(height: 5)
            }
            .padding(.top, 14)

            // 3-cell micro stats row
            HStack(spacing: 1) {
                PaceMicroCell(
                    label: "Avg / day",
                    value: "\(avgPerDay)",
                    accent: false,
                    theme: theme
                )
                PaceMicroCell(
                    label: "Streak",
                    value: "\(streak) d",
                    accent: streak >= 7,
                    theme: theme
                )
                PaceMicroCell(
                    label: onTrack ? "Days ahead" : "Days behind",
                    value: "\(drift)",
                    accent: !onTrack,
                    theme: theme
                )
            }
            .background(Color.black.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, 10)

            Text(driftCaption)
                .font(.custom("EB Garamond", size: 11))
                .italic()
                .lineSpacing(3)
                .foregroundStyle(theme.textPrimary.opacity(0.65))
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(theme.page)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.foil, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var paceStatusPill: some View {
        Text(onTrack ? "ON TRACK" : "GENTLE DRIFT")
            .font(.system(size: 10))
            .kerning(1.4)
            .foregroundStyle(onTrack ? Color(hex: "#3D5A28") : Color(hex: "#7A3818"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    onTrack
                    ? Color(hex: "#5A7D3F").opacity(0.13)
                    : Color(hex: "#B86822").opacity(0.20)
                )
            )
    }

    private var driftCaption: String {
        if onTrack {
            if drift == 0 {
                return "At this pace, you'll finish on the day you chose."
            }
            return "At this pace, you'll finish \(drift) day\(drift == 1 ? "" : "s") early."
        } else {
            let needed = Int(ceil(Double(remaining) / Double(max(1, daysRemaining))))
            return "At this pace, completion shifts \(drift) day\(drift == 1 ? "" : "s") past your chosen day. \(needed) per day brings you back."
        }
    }

    // MARK: - Goal slider

    private var goalSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("DAYS YOU'D LIKE TO TAKE")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                (
                    Text("\(koti.goalDays)")
                        .font(.custom("EB Garamond", size: 16))
                    +
                    Text(" days")
                        .font(.custom("EB Garamond", size: 11))
                        .foregroundColor(theme.textPrimary.opacity(0.55))
                )
            }

            let binding = Binding<Double>(
                get: { Double(koti.goalDays) },
                set: { newValue in
                    let v = Int(newValue.rounded())
                    koti.goalDays = v
                    scheduleGoalDebounce(value: v)
                }
            )

            Slider(value: binding, in: 30...730, step: 1)
                .tint(theme.cloth)

            HStack {
                Text("30 days").monospacedDigit()
                Spacer()
                Text("\(Int(ceil(Double(remaining) / Double(max(1, koti.goalDays))))) / day")
                    .monospacedDigit()
                Spacer()
                Text("2 years").monospacedDigit()
            }
            .font(.system(size: 10))
            .foregroundStyle(theme.textPrimary.opacity(0.5))
        }
    }

    private func scheduleGoalDebounce(value: Int) {
        pendingGoalDays = value
        goalDebounceTask?.cancel()
        goalDebounceTask = Task { [value] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                if pendingGoalDays == value {
                    onGoalDaysChanged(value)
                    pendingGoalDays = nil
                }
            }
        }
    }

    // MARK: - Calendar block

    @State private var calendarOffset: Int = 0  // page offset in 30-day windows
    @State private var selectedDay: Date? = nil

    private var calendarBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("THE LAST 30 DAYS")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Text("each page · one day")
                    .font(.custom("EB Garamond", size: 10))
                    .italic()
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
            }

            CalendarView(
                history: history,
                offset: $calendarOffset,
                selected: $selectedDay,
                max: maxInHistory,
                theme: theme,
                inkColor: koti.inkColor
            )

            HStack {
                Text("numbers shown · darker means more")
                    .font(.custom("EB Garamond", size: 10))
                    .italic()
                Spacer()
                Text("tap a day for the exact count")
                    .font(.custom("EB Garamond", size: 10))
                    .italic()
            }
            .foregroundStyle(theme.textPrimary.opacity(0.6))
        }
    }

    // MARK: - Reminders

    private static let reminderSlots: [ReminderSlot] = [
        ReminderSlot(id: "brahma",   time: "04:30", label: "Brāhma Muhūrta", sub: "before dawn"),
        ReminderSlot(id: "pratah",   time: "07:00", label: "Prātaḥkāl",      sub: "morning"),
        ReminderSlot(id: "madhyana", time: "12:30", label: "Madhyāna",       sub: "midday"),
        ReminderSlot(id: "sandhya",  time: "19:00", label: "Sandhyā",        sub: "evening"),
    ]

    private var remindersBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("REMINDERS · AT MOST THREE")
                .font(.system(size: 10))
                .kerning(1.6)
                .foregroundStyle(theme.textPrimary.opacity(0.55))
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(Self.reminderSlots.enumerated()), id: \.element.id) { idx, slot in
                    if idx > 0 {
                        Divider()
                            .background(Color.black.opacity(0.07))
                    }
                    ReminderRow(
                        slot: slot,
                        isOn: koti.reminderTimes.contains(slot.id),
                        canEnable: koti.reminderTimes.count < 3,
                        theme: theme,
                        onToggle: { toggleReminder(slot.id) }
                    )
                }
            }
            .background(theme.page)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.foil, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let first = koti.reminderTimes.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Each reminder is a quiet line, not a demand:")
                        .font(.custom("EB Garamond", size: 11))
                        .italic()
                        .foregroundStyle(theme.textPrimary.opacity(0.75))
                    Text("“\(reminderCopy(slot: first, target: todayTarget, done: todayDone))”")
                        .font(.custom("EB Garamond", size: 11))
                        .foregroundStyle(theme.textPrimary.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.top, 12)
            }
        }
    }

    private func toggleReminder(_ id: String) {
        var next = koti.reminderTimes
        if let idx = next.firstIndex(of: id) {
            next.remove(at: idx)
        } else if next.count < 3 {
            next.append(id)
        } else {
            return  // hard cap; row is dimmed and shouldn't have been tappable
        }
        koti.reminderTimes = next
        onRemindersChanged(next)
    }

    // MARK: - Footer note

    private var footerNote: some View {
        Text("The pace is a suggestion, never a demand. Quiet days are part of the practice. The koti will wait.")
            .font(.custom("EB Garamond", size: 11))
            .italic()
            .lineSpacing(3)
            .foregroundStyle(theme.textPrimary.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.black.opacity(0.12), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func formattedIN(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }

    private func dateLabel(_ date: Date, format: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = format
        return f.string(from: date)
    }
}

// MARK: - Sub-views

/// Reminder slot record used by both the row and the copy generator.
public struct ReminderSlot: Hashable, Sendable {
    public let id: String
    public let time: String
    public let label: String
    public let sub: String
}

/// One row in the reminders list. iOS-style toggle on the trailing edge.
struct ReminderRow: View {
    let slot: ReminderSlot
    let isOn: Bool
    let canEnable: Bool
    let theme: any Theme
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Text(slot.time)
                    .font(.custom("EB Garamond", size: 18).monospacedDigit())
                    .frame(minWidth: 54, alignment: .leading)
                    .foregroundStyle(isOn ? theme.cloth : theme.textPrimary.opacity(0.55))

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.label)
                        .font(.custom("EB Garamond", size: 15))
                        .italic()
                        .foregroundStyle(theme.textPrimary)
                    Text(slot.sub)
                        .font(.system(size: 10))
                        .kerning(0.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.55))
                }
                Spacer()
                ToggleSwitch(isOn: isOn, color: theme.cloth)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isOn ? Color.white.opacity(0.5) : Color.clear)
            .opacity((!isOn && !canEnable) ? 0.4 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isOn && !canEnable)
    }
}

/// Mini iOS-style toggle that matches the design's 32×18 capsule.
struct ToggleSwitch: View {
    let isOn: Bool
    let color: Color
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? color : Color.black.opacity(0.12))
                .frame(width: 32, height: 18)
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }
}

/// One micro-stat cell inside the today-block 3-up row.
struct PaceMicroCell: View {
    let label: String
    let value: String
    let accent: Bool
    let theme: any Theme
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9))
                .kerning(1.4)
                .foregroundStyle(theme.textPrimary.opacity(0.55))
            Text(value)
                .font(.custom("EB Garamond", size: 17).monospacedDigit())
                .foregroundStyle(accent ? theme.cloth : theme.textPrimary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.page)
    }
}

// MARK: - Calendar view

/// 30-day heat-map. Paginates in 30-day windows; `‹` older, `›` newer.
struct CalendarView: View {
    let history: [(date: Date, count: Int)]
    @Binding var offset: Int
    @Binding var selected: Date?
    let max: Int
    let theme: any Theme
    let inkColor: Color

    private let windowSize = 30

    /// Slice of `history` shown right now (oldest → newest within the window).
    private var visible: [(date: Date, count: Int)] {
        guard !history.isEmpty else { return [] }
        let end = history.count - offset
        let start = Swift.max(0, end - windowSize)
        guard end > start else { return [] }
        return Array(history[start..<end])
    }

    private var maxOffset: Int { Swift.max(0, history.count - windowSize) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            paginationBar
            if visible.isEmpty {
                Text("No history yet — your first day starts the calendar.")
                    .font(.custom("EB Garamond", size: 11))
                    .italic()
                    .foregroundStyle(theme.textPrimary.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                grid
                previewRow
            }
        }
    }

    private var paginationBar: some View {
        HStack {
            navButton(symbol: "‹", disabled: offset >= maxOffset) {
                offset = Swift.min(maxOffset, offset + windowSize)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(rangeLabel)
                    .font(.custom("EB Garamond", size: 14).monospacedDigit())
                    .kerning(0.3)
                if offset > 0 {
                    Button(action: { offset = 0 }) {
                        Text("JUMP TO TODAY")
                            .font(.system(size: 9))
                            .kerning(1.4)
                            .foregroundStyle(theme.cloth.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            navButton(symbol: "›", disabled: offset == 0) {
                offset = Swift.max(0, offset - windowSize)
            }
        }
        .padding(.horizontal, 2)
    }

    private var rangeLabel: String {
        guard let first = visible.first?.date, let last = visible.last?.date else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        return "\(f.string(from: first))  →  \(f.string(from: last))"
    }

    private func navButton(symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 14))
                .foregroundStyle(disabled ? theme.textPrimary.opacity(0.3) : theme.textPrimary)
                .frame(width: 26, height: 26)
                .background(theme.page)
                .overlay(
                    Circle().stroke(disabled ? Color.black.opacity(0.08) : theme.foil, lineWidth: 0.5)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    /// Weeks in the window, padded so the first row starts on the correct
    /// weekday column. Calendar week starts Monday.
    private var weeks: [[(date: Date, count: Int)?]] {
        guard let first = visible.first?.date else { return [] }
        let weekday = Calendar.current.component(.weekday, from: first)   // Sun=1 … Sat=7
        let leadingPad = (weekday + 5) % 7                                  // Mon=0
        var padded: [(date: Date, count: Int)?] = Array(repeating: nil, count: leadingPad)
        padded.append(contentsOf: visible.map { Optional($0) })
        var rows: [[(date: Date, count: Int)?]] = []
        var idx = 0
        while idx < padded.count {
            let end = Swift.min(idx + 7, padded.count)
            var row = Array(padded[idx..<end])
            while row.count < 7 { row.append(nil) }
            rows.append(row)
            idx += 7
        }
        return rows
    }

    private var grid: some View {
        VStack(spacing: 3) {
            // Header row — weekday labels (Mon..Sun)
            HStack(spacing: 3) {
                Spacer().frame(width: 22)
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 9))
                        .kerning(1)
                        .foregroundStyle(theme.textPrimary.opacity(0.45))
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 3) {
                    Text(monthLabel(for: week))
                        .font(.system(size: 9))
                        .kerning(0.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.4))
                        .frame(width: 22, alignment: .trailing)
                    ForEach(0..<7, id: \.self) { di in
                        if let day = week[di] {
                            CalendarCell(
                                day: day,
                                isToday: Calendar.current.isDateInToday(day.date),
                                isSelected: selected.map { Calendar.current.isDate($0, inSameDayAs: day.date) } ?? false,
                                max: max,
                                theme: theme,
                                inkColor: inkColor,
                                onTap: {
                                    if let s = selected, Calendar.current.isDate(s, inSameDayAs: day.date) {
                                        selected = nil
                                    } else {
                                        selected = day.date
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 42)
                        }
                    }
                }
            }
        }
    }

    /// Find the first day-of-month entry within the row (≤ 7) and emit its
    /// short month, lowercased. Empty otherwise.
    private func monthLabel(for week: [(date: Date, count: Int)?]) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM"
        for cell in week {
            if let cell, Calendar.current.component(.day, from: cell.date) <= 7 {
                return f.string(from: cell.date).lowercased()
            }
        }
        return ""
    }

    private var previewRow: some View {
        let active = selected.flatMap { sel in
            history.first { Calendar.current.isDate($0.date, inSameDayAs: sel) }
        }
        return HStack(alignment: .firstTextBaseline) {
            if let active {
                VStack(alignment: .leading, spacing: 2) {
                    Text(longDateLabel(active.date))
                        .font(.custom("EB Garamond", size: 15))
                    Text(active.count == 0
                         ? "a quiet day"
                         : "\(formattedIN(active.count)) mantras written")
                        .font(.system(size: 10))
                        .kerning(0.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.55))
                }
                Spacer()
                if active.count > 0 {
                    Text("✦")
                        .font(.custom("EB Garamond", size: 22))
                        .foregroundStyle(inkColor.opacity(0.7))
                }
            } else {
                Text("Tap a day for its count")
                    .font(.custom("EB Garamond", size: 11))
                    .italic()
                    .foregroundStyle(theme.textPrimary.opacity(0.45))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(theme.page)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected != nil ? theme.foil : Color.black.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    private func longDateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }

    private func formattedIN(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}

/// One day cell in the heat-map.
struct CalendarCell: View {
    let day: (date: Date, count: Int)
    let isToday: Bool
    let isSelected: Bool
    let max: Int
    let theme: any Theme
    let inkColor: Color
    let onTap: () -> Void

    private var intensity: Double {
        day.count == 0 ? 0 : Swift.min(1.0, Double(day.count) / Double(Swift.max(1, max)))
    }
    private var cellOpacity: Double {
        day.count == 0 ? 1 : 0.18 + intensity * 0.82
    }
    private var textOnInk: Bool { intensity > 0.5 }

    private var compactCount: String {
        if day.count == 0 { return "·" }
        if day.count >= 1000 {
            let k = Double(day.count) / 1000.0
            if day.count >= 10000 {
                return "\(Int(k))k"
            }
            let s = String(format: "%.1f", k)
            return (s.hasSuffix(".0") ? String(s.dropLast(2)) : s) + "k"
        }
        return "\(day.count)"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.system(size: 8).monospacedDigit())
                    .kerning(0.3)
                    .foregroundStyle(textOnInk
                                     ? Color.white.opacity(0.7)
                                     : Color.black.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                Text(compactCount)
                    .font(.custom("EB Garamond", size: day.count == 0 ? 14 : 12).monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(
                        textOnInk
                        ? Color.white.opacity(0.95)
                        : (day.count == 0 ? Color.black.opacity(0.25) : theme.textPrimary)
                    )
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .frame(height: 42)
            .background(day.count == 0 ? Color.black.opacity(0.04) : inkColor)
            .opacity(cellOpacity)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isToday ? theme.foil : (isSelected ? theme.cloth : Color.clear),
                        lineWidth: 1.2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reminder copy

/// Notification preview copy for a given slot. Public so the caller can use
/// the same copy in its scheduled `UNUserNotificationCenter` requests.
public func reminderCopy(slot: String, target: Int, done: Int) -> String {
    let remaining = max(0, target - done)
    switch slot {
    case "brahma":
        return "The hour before dawn is yours. \(remaining) remain for today."
    case "pratah":
        return remaining > 0
            ? "Good morning. \(remaining) mantras await you today."
            : "Good morning. You have finished today's measure already."
    case "madhyana":
        return remaining > 0
            ? "A few minutes between meetings. \(remaining) left."
            : "A few minutes between meetings. You're ahead — rest if you wish."
    case "sandhya":
        return remaining > 0
            ? "Evening light. \(remaining) more to close the day."
            : "Evening light. The day's measure is done. Sit a moment."
    default:
        return ""
    }
}
