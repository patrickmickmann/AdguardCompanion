import SwiftUI

extension QueryOutcome {
    /// Short label for list rows and badges.
    var title: String {
        switch self {
        case .allowed: "Erlaubt"
        case .allowlisted: "Zugelassen"
        case .blocked: "Blockiert"
        case .rewritten(.safeSearch): "Safe Search"
        case .rewritten: "Umgeschrieben"
        case .failed: "Fehler"
        case .unknown: "Unbekannt"
        }
    }

    /// Explanation for the detail view.
    var detail: String {
        switch self {
        case .allowed: "Keine Regel hat gegriffen"
        case .allowlisted: "Durch eine Allowlist-Regel zugelassen"
        case .blocked(.filterRule): "Durch eine Filterregel blockiert"
        case .blocked(.safeBrowsing): "Durch Safe Browsing blockiert"
        case .blocked(.parentalControl): "Durch die Kindersicherung blockiert"
        case .blocked(.blockedService): "Durch einen gesperrten Dienst blockiert"
        case .blocked(.invalid): "Ungültige Anfrage blockiert"
        case .rewritten(.rewrite): "Durch eine DNS-Umschreibung beantwortet"
        case .rewritten(.hostsFile): "Durch die Hosts-Datei beantwortet"
        case .rewritten(.safeSearch): "Auf die sichere Suche umgeleitet"
        case .failed: "Bei der Filterung ist ein Fehler aufgetreten"
        case let .unknown(reason): "Grund: \(reason)"
        }
    }

    var systemImage: String {
        switch self {
        case .allowed: "checkmark"
        case .allowlisted: "checkmark.seal.fill"
        case .blocked: "hand.raised.fill"
        case .rewritten: "arrow.triangle.swap"
        case .failed: "exclamationmark.triangle.fill"
        case .unknown: "questionmark"
        }
    }

    var tint: Color {
        switch self {
        case .allowed, .allowlisted: AppColor.protection
        case .blocked: AppColor.blocked
        case .rewritten: AppColor.network
        case .failed: AppColor.warning
        case .unknown: .gray
        }
    }
}

extension QueryLogFilter {
    var title: LocalizedStringKey {
        switch self {
        case .all: "Alle Anfragen"
        case .blocked: "Blockiert"
        case .allowed: "Erlaubt"
        case .rewritten: "Umgeschrieben"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "tray.full"
        case .blocked: "hand.raised"
        case .allowed: "checkmark.circle"
        case .rewritten: "arrow.triangle.swap"
        }
    }
}

/// Round status glyph used in rows and the detail header.
struct OutcomeBadge: View {
    let outcome: QueryOutcome
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: outcome.systemImage)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(outcome.tint)
            .frame(width: size, height: size)
            .background(outcome.tint.opacity(0.15), in: .circle)
            .accessibilityHidden(true)
    }
}
