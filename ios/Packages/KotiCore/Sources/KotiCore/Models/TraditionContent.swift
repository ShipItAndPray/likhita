import Foundation

/// Per-tradition copy + glyph data driven by the design package.
/// Mirrors `TRADITIONS` in the design's data.jsx.
public struct TraditionContent: Sendable, Hashable {
    public let appName: String
    public let practice: String
    public let practiceLocal: String
    public let mantra: String
    public let mantraTyped: String
    public let scriptKey: String           // "telugu" | "devanagari"
    public let displayFontKey: String      // matches Theme.displayFontName
    public let temple: String
    public let templeFull: String
    public let templeLocale: String
    public let pledge: String
    public let jaya: String
    public let beginLabel: String
    public let continueLabel: String
    public let backLabel: String

    public init(
        appName: String,
        practice: String,
        practiceLocal: String,
        mantra: String,
        mantraTyped: String,
        scriptKey: String,
        displayFontKey: String,
        temple: String,
        templeFull: String,
        templeLocale: String,
        pledge: String,
        jaya: String,
        beginLabel: String,
        continueLabel: String,
        backLabel: String
    ) {
        self.appName = appName
        self.practice = practice
        self.practiceLocal = practiceLocal
        self.mantra = mantra
        self.mantraTyped = mantraTyped
        self.scriptKey = scriptKey
        self.displayFontKey = displayFontKey
        self.temple = temple
        self.templeFull = templeFull
        self.templeLocale = templeLocale
        self.pledge = pledge
        self.jaya = jaya
        self.beginLabel = beginLabel
        self.continueLabel = continueLabel
        self.backLabel = backLabel
    }

    public var templeShort: String {
        temple.split(separator: ",").first.map(String.init) ?? temple
    }
}

public extension Tradition {
    var content: TraditionContent {
        switch self {
        case .telugu:
            return TraditionContent(
                appName: "Likhita Rama",
                practice: "Rama Koti",
                practiceLocal: "రామ కోటి",
                mantra: "శ్రీరామ",
                mantraTyped: "srirama",
                scriptKey: "telugu",
                displayFontKey: "TiroTelugu-Regular",
                temple: "Bhadrachalam",
                templeFull: "Sri Sita Ramachandra Swamy Temple",
                templeLocale: "Telangana, on the Godavari",
                pledge: "నేను ఈ రామ కోటిని భక్తితో ఆరంభిస్తున్నాను. shortcuts ఉపయోగించను. ప్రతి శ్రీరామను శ్రద్ధతో వ్రాస్తాను. శ్రీరామ జయం.",
                jaya: "శ్రీరామ జయం",
                beginLabel: "ఆరంభించు",
                continueLabel: "కొనసాగించు",
                backLabel: "వెనుకకు"
            )
        case .hindi:
            return TraditionContent(
                appName: "Likhita Ram",
                practice: "Ram Naam Lekhan",
                practiceLocal: "राम नाम लेखन",
                mantra: "राम",
                mantraTyped: "ram",
                scriptKey: "devanagari",
                displayFontKey: "TiroDevanagariHindi-Regular",
                temple: "Ram Naam Bank, Varanasi",
                templeFull: "Ram Naam Bank · est. 1926",
                templeLocale: "Banaras, on the Ganga",
                pledge: "मैं यह राम नाम लेखन श्रद्धा से आरंभ करता/करती हूँ। मैं कोई shortcut नहीं लूँगा/लूँगी। प्रत्येक राम-नाम को मन से लिखूँगा/लिखूँगी। जय श्री राम।",
                jaya: "जय श्री राम",
                beginLabel: "आरंभ",
                continueLabel: "आगे",
                backLabel: "पीछे"
            )
        }
    }
}
