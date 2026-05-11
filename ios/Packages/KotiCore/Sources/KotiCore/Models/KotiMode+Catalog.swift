import Foundation

/// Full mode catalog from the design (data.jsx). The base `KotiMode` enum
/// only carries trial/lakh/crore for v1 backend compatibility — the design
/// surfaces six selectable modes in onboarding step 2, so we extend with a
/// parallel `KotiModePlan` value type for UI selection. Plans map onto the
/// closest `KotiMode` for persistence.
public struct KotiModePlan: Identifiable, Sendable, Hashable {
    public let key: String
    public let label: String
    public let local: String
    public let count: Int64
    public let duration: String
    public let pages: Int
    public let recommended: Bool
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
        backingMode: KotiMode
    ) {
        self.key = key
        self.label = label
        self.local = local
        self.count = count
        self.duration = duration
        self.pages = pages
        self.recommended = recommended
        self.backingMode = backingMode
    }
}

public enum KotiModeCatalog {
    public static let plans: [KotiModePlan] = [
        .init(key: "trial",     label: "Trial",          local: "పరీక్ష",      count: 1_000,      duration: "1 hour",        pages: 7,      recommended: false, backingMode: .trial),
        .init(key: "daily",     label: "Daily Practice", local: "రోజువారీ",    count: 11_000,     duration: "1–2 weeks",     pages: 73,     recommended: false, backingMode: .lakh),
        .init(key: "sankalpa",  label: "Sankalpa",       local: "సంకల్ప",       count: 51_000,     duration: "1–3 months",    pages: 340,    recommended: false, backingMode: .lakh),
        .init(key: "lakh",      label: "Lakh",           local: "లక్ష",         count: 100_000,    duration: "3–12 months",   pages: 666,    recommended: true,  backingMode: .lakh),
        .init(key: "maha",      label: "Maha Sankalpa",  local: "మహా సంకల్ప",   count: 116_000,    duration: "4–14 months",   pages: 773,    recommended: false, backingMode: .lakh),
        .init(key: "crore",     label: "Crore",          local: "కోటి",         count: 10_000_000, duration: "lifetime",      pages: 66_666, recommended: false, backingMode: .crore),
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
