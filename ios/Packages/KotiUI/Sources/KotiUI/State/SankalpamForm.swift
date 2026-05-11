import Foundation
import SwiftUI
import KotiCore

/// Shared form state across the sankalpam steps and into the writing flow.
/// Mirrors the design's `form` object in app.jsx, but typed.
@MainActor
@Observable
public final class SankalpamForm {
    public var name: String = ""
    public var gotra: String = ""
    public var nativePlace: String = ""
    public var email: String = ""
    public var dedicationText: String = ""
    public var dedicationTo: DedicationPreset? = nil
    public var modePlanKey: String = "lakh"
    public var inkHex: String = "#E34234"
    public var themeKey: ThemeKey = .bhadrachalamClassic
    public var handwritingSamples: [HandwritingStrokeStorage] = []

    public init() {}

    public var modePlan: KotiModePlan { KotiModeCatalog.plan(forKey: modePlanKey) }
}

/// Marker so SwiftUI's @Observable observers don't need to depend on
/// KotiUI's stroke point type. Concrete strokes live in the canvas view's
/// local state during calibration.
public struct HandwritingStrokeStorage: Hashable, Sendable {
    public let id: UUID
    public init(id: UUID = UUID()) { self.id = id }
}
