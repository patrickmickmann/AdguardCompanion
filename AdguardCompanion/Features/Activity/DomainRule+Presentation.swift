import SwiftUI

extension DomainRuleState {
    var title: String {
        switch self {
        case .none: "Keine – Filterlisten entscheiden"
        case .blocked: "Gesperrt"
        case .allowed: "Erlaubt"
        }
    }

    var tint: Color {
        switch self {
        case .none: .secondary
        case .blocked: AppColor.blocked
        case .allowed: AppColor.protection
        }
    }
}

extension DomainRuleChange {
    var actionTitle: String {
        switch self {
        case .block: "Domain sperren"
        case .allow: "Domain erlauben"
        case .remove: "Eigene Regel entfernen"
        }
    }

    var systemImage: String {
        switch self {
        case .block: "hand.raised.fill"
        case .allow: "checkmark.shield.fill"
        case .remove: "arrow.uturn.backward"
        }
    }

    var tint: Color {
        switch self {
        case .block: AppColor.blocked
        case .allow: AppColor.protection
        case .remove: AppColor.network
        }
    }

    var buttonRole: ButtonRole? {
        self == .block ? .destructive : nil
    }

    var confirmationTitle: String {
        switch self {
        case .block: "Domain sperren?"
        case .allow: "Domain erlauben?"
        case .remove: "Eigene Regel entfernen?"
        }
    }

    /// Kept free of the domain itself: long names would be hyphenated in the
    /// dialog and could be misread. The domain is visible right above.
    var confirmationMessage: String {
        switch self {
        case .block:
            "Diese Domain und ihre Subdomains werden für alle Geräte blockiert, auch wenn eine Filterliste sie erlaubt."
        case .allow:
            "Diese Domain und ihre Subdomains werden für alle Geräte erlaubt, auch wenn eine Filterliste sie blockiert."
        case .remove:
            "Danach entscheiden für diese Domain wieder die Filterlisten und übrigen Einstellungen."
        }
    }
}
