import Foundation

/// Six-rung traditional ladder offered in onboarding step 2 (design v2
/// data.jsx). Counts are anchored in mala (rosary) practice — 108-based
/// numbers are auspicious. Each plan maps onto a closest backend `KotiMode`
/// for persistence (the backend currently knows only trial/lakh/crore).
public struct KotiModePlan: Identifiable, Sendable, Hashable {
    public let key: String
    public let label: String
    public let local: String
    public let count: Int64
    public let duration: String
    public let pages: Int
    public let recommended: Bool
    /// One-line italic gloss displayed under the row.
    public let note: String
    public let backingMode: KotiMode

    public var id: String { key }

    public init(
        key: String,
        label: String,
        local: String,
        count: Int64,
        duration: String,
        pages: Int,
        recommended: Bool,
        note: String,
        backingMode: KotiMode
    ) {
        self.key = key
        self.label = label
        self.local = local
        self.count = count
        self.duration = duration
        self.pages = pages
        self.recommended = recommended
        self.note = note
        self.backingMode = backingMode
    }
}

public enum KotiModeCatalog {
    public static let plans: [KotiModePlan] = [
        .init(key: "japa",     label: "Japa",              local: "జప",            count: 108,        duration: "one sitting",  pages: 1,
              recommended: false, note: "One mala. The traditional starting point.",                       backingMode: .trial),
        .init(key: "nitya",    label: "Nitya",             local: "నిత్య",          count: 1_008,      duration: "one day",      pages: 7,
              recommended: false, note: "Ten malas. A full day of practice.",                              backingMode: .trial),
        .init(key: "sankalpa", label: "Sankalpa",          local: "సంకల్ప",         count: 51_000,     duration: "1–3 months",   pages: 340,
              recommended: false, note: "A vowed offering. Auspicious count.",                             backingMode: .lakh),
        .init(key: "lakh",     label: "Lakh",              local: "లక్ష",           count: 100_000,    duration: "3–12 months",  pages: 666,
              recommended: true,  note: "A major milestone on the path to koti.",                          backingMode: .lakh),
        .init(key: "sahasra",  label: "Sahasra-sankalpa",  local: "సహస్ర సంకల్ప",   count: 108_000,    duration: "4–14 months",  pages: 720,
              recommended: false, note: "One thousand times one hundred and eight.",                       backingMode: .lakh),
        .init(key: "crore",    label: "Koti",              local: "కోటి",           count: 10_000_000, duration: "a lifetime",   pages: 66_666,
              recommended: false, note: "The canonical Rama Koti. The reason this practice has its name.", backingMode: .crore),
    ]

    public static func plan(forKey key: String) -> KotiModePlan {
        plans.first(where: { $0.key == key }) ?? plans[3]
    }
}

/// Six dedication chip presets shown in onboarding step 2.
public enum DedicationPreset: String, CaseIterable, Sendable {
    case `self`
    case parent
    case child
    case departed
    case family
    case cause

    public var label: String {
        switch self {
        case .self:     return "Myself"
        case .parent:   return "A parent"
        case .child:    return "A child"
        case .departed: return "A departed soul"
        case .family:   return "My family"
        case .cause:    return "A cause"
        }
    }
}

/// Named ink swatches for stylus calibration. Keys match the `InkSwatch.palette`
/// hex values one-to-one and the design's INKS array.
public struct InkOption: Sendable, Hashable, Identifiable {
    public let name: String
    public let hex: String
    public var id: String { hex }

    public init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }
}

public enum InkPalette {
    public static let options: [InkOption] = [
        .init(name: "Vermillion",   hex: "#E34234"),
        .init(name: "Kumkum",       hex: "#B81D2A"),
        .init(name: "Saffron",      hex: "#E26B1A"),
        .init(name: "Marigold",     hex: "#E89422"),
        .init(name: "Indigo",       hex: "#3A2766"),
        .init(name: "Lamp-black",   hex: "#1A1410"),
        .init(name: "Sandalwood",   hex: "#8B5A36"),
        .init(name: "Gold",         hex: "#B89033"),
        .init(name: "Tulsi green",  hex: "#4A6B30"),
        .init(name: "Peacock blue", hex: "#0E5570"),
        .init(name: "Earthen red",  hex: "#7A3018"),
        .init(name: "Royal purple", hex: "#3F1A52"),
    ]

    public static func name(forHex hex: String) -> String {
        options.first(where: { $0.hex.caseInsensitiveCompare(hex) == .orderedSame })?.name ?? "Custom"
    }
}
