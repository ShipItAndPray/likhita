import Foundation

/// A node on the Ramayana journey path (design §core-screens RamayanaPath).
public struct Milestone: Sendable, Hashable, Identifiable {
    public let key: String
    public let fraction: Double
    public let teluguLabel: String
    public let hindiLabel: String
    public let englishLabel: String
    public let note: String

    public var id: String { key }

    public init(key: String, fraction: Double, teluguLabel: String, hindiLabel: String, englishLabel: String, note: String) {
        self.key = key
        self.fraction = fraction
        self.teluguLabel = teluguLabel
        self.hindiLabel = hindiLabel
        self.englishLabel = englishLabel
        self.note = note
    }

    public func label(for tradition: Tradition) -> String {
        switch tradition {
        case .telugu: return teluguLabel
        case .hindi:  return hindiLabel
        }
    }
}

public enum MilestoneCatalog {
    public static let path: [Milestone] = [
        .init(key: "ayodhya",    fraction: 0.00, teluguLabel: "అయోధ్య",       hindiLabel: "अयोध्या",     englishLabel: "Ayodhya",        note: "The vow begins. Palace gates open at dawn."),
        .init(key: "chitrakoot", fraction: 0.10, teluguLabel: "చిత్రకూటం",   hindiLabel: "चित्रकूट",    englishLabel: "Chitrakoot",     note: "Forest ashram. Stillness settles in."),
        .init(key: "panchavati", fraction: 0.25, teluguLabel: "పంచవటి",       hindiLabel: "पंचवटी",      englishLabel: "Panchavati",     note: "Riverside hut. The golden deer appears."),
        .init(key: "kishkindha", fraction: 0.50, teluguLabel: "కిష్కింధ",     hindiLabel: "किष्किंधा",   englishLabel: "Kishkindha",     note: "Hanuman meets Rama. The search begins."),
        .init(key: "setu",       fraction: 0.75, teluguLabel: "సేతు",          hindiLabel: "सेतु",         englishLabel: "Setu",           note: "A bridge of stones across the sea."),
        .init(key: "lanka",      fraction: 0.90, teluguLabel: "లంక",           hindiLabel: "लंका",         englishLabel: "Lanka",          note: "The fortress falls. Dharma holds."),
        .init(key: "pattabhi",   fraction: 1.00, teluguLabel: "పట్టాభిషేకం",  hindiLabel: "राज्याभिषेक",  englishLabel: "Pattabhishekam", note: "Coronation. Sita beside Rama."),
    ]

    /// Index of the highest milestone whose fraction <= progress.
    public static func currentIndex(forProgress progress: Double) -> Int {
        var last = 0
        for (i, m) in path.enumerated() where progress >= m.fraction {
            last = i
        }
        return last
    }
}
