import Foundation
import SwiftUI

/// Strongly-typed accessors for the shared `Localizable.xcstrings` catalog.
/// Using `LocalizedStringKey` means SwiftUI does the runtime locale lookup
/// against this package's bundle automatically.
public enum L10n {
    public static let bundle = Bundle.module

    public enum Common {
        public static let welcome     = LocalizedStringKey("common.welcome")
        public static let begin       = LocalizedStringKey("common.begin")
        public static let `continue`  = LocalizedStringKey("common.continue")
        public static let cancel      = LocalizedStringKey("common.cancel")
        public static let complete    = LocalizedStringKey("common.complete")
    }

    public enum Sankalpam {
        public static let title       = LocalizedStringKey("sankalpam.title")
        public static let dedication  = LocalizedStringKey("sankalpam.dedication")
        public static let mode        = LocalizedStringKey("sankalpam.mode")
        public static let theme       = LocalizedStringKey("sankalpam.theme")
    }

    /// String version (for non-SwiftUI call sites, e.g. notification bodies).
    public static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }
}
