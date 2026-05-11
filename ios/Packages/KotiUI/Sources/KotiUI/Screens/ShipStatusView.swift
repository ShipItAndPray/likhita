import SwiftUI
import KotiCore
import KotiThemes

/// Linear progress timeline — printing → in transit → at temple →
/// photographed → receipt mailed.
public struct ShipStatusView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let onDone: () -> Void

    public init(tradition: TraditionContent, theme: any Theme, onDone: @escaping () -> Void) {
        self.tradition = tradition
        self.theme = theme
        self.onDone = onDone
    }

    private struct Step {
        let label: String
        let date: String
        let isCurrent: Bool
    }

    private var steps: [Step] {
        [
            Step(label: "Printing in Hyderabad",            date: "Apr 12 – May 3", isCurrent: false),
            Step(label: "Quarterly batch in transit",        date: "May 6",          isCurrent: false),
            Step(label: "At \(tradition.templeShort)",       date: "May 9",          isCurrent: false),
            Step(label: "Photographed in the Mandapam",      date: "May 10",         isCurrent: true),
            Step(label: "Receipt mailed to you",             date: "by May 24",      isCurrent: false),
        ]
    }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("SHIP STATUS")
                        .font(.system(size: 11))
                        .kerning(2)
                        .foregroundStyle(theme.textPrimary.opacity(0.55))
                    Spacer()
                    Button(action: onDone) {
                        Text("Done")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.textPrimary.opacity(0.6))
                    }
                }
                Text("Your book is on its way to \(tradition.templeShort).")
                    .font(.custom("EB Garamond", size: 26))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.top, 12)

                GoldRule(foil: theme.foil, width: 300)
                    .padding(.top, 14)

                let currentIdx = steps.firstIndex(where: { $0.isCurrent }) ?? 0
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.foil, lineWidth: 1)
                                        .background(
                                            Circle().fill(i <= currentIdx ? theme.foil : Color.clear)
                                        )
                                        .frame(width: 14, height: 14)
                                    if s.isCurrent {
                                        Circle()
                                            .stroke(theme.foil.opacity(0.2), lineWidth: 4)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                if i < steps.count - 1 {
                                    Rectangle()
                                        .fill(i < currentIdx ? theme.foil : Color.black.opacity(0.15))
                                        .frame(width: 1, height: 36)
                                        .padding(.top, 2)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.label)
                                    .font(.custom("EB Garamond", size: 16))
                                    .foregroundStyle(theme.textPrimary)
                                Text(s.date)
                                    .font(.system(size: 11))
                                    .kerning(0.4)
                                    .foregroundStyle(theme.textPrimary.opacity(0.65))
                            }
                            .opacity(i <= currentIdx ? 1 : 0.55)
                            .padding(.bottom, 18)
                            Spacer()
                        }
                    }
                }
                .padding(.top, 24)

                Spacer()

                Text("When your book is photographed at the temple, you will receive a notification with the photograph and a temple-stamped receipt. \(tradition.jaya).")
                    .font(.custom("EB Garamond", size: 12))
                    .italic()
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(theme.page)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(theme.foil, lineWidth: 0.5)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.top, 54)
            .padding(.bottom, 36)
        }
        .foregroundStyle(theme.textPrimary)
    }
}
