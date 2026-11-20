import SwiftUI

/// The individually switchable protection features.
enum ProtectionFeature: CaseIterable, Identifiable {
    case safeBrowsing, parentalControl, safeSearch

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .safeBrowsing: "Safe Browsing"
        case .parentalControl: "Kindersicherung"
        case .safeSearch: "Safe Search"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .safeBrowsing: "Blockiert bekannte Phishing- und Schadsoftware-Domains."
        case .parentalControl: "Blockiert Websites mit Inhalten für Erwachsene."
        case .safeSearch: "Erzwingt sichere Suche bei unterstützten Suchmaschinen."
        }
    }

    var systemImage: String {
        switch self {
        case .safeBrowsing: "exclamationmark.shield.fill"
        case .parentalControl: "figure.and.child.holdinghands"
        case .safeSearch: "magnifyingglass"
        }
    }

    var color: Color {
        switch self {
        case .safeBrowsing: AppColor.warning
        case .parentalControl: Color(uiColor: .systemPurple)
        case .safeSearch: AppColor.network
        }
    }

    func value(in settings: ProtectionSettings) -> Bool {
        switch self {
        case .safeBrowsing: settings.safeBrowsing
        case .parentalControl: settings.parentalControl
        case .safeSearch: settings.safeSearch
        }
    }

    func change(to isOn: Bool) -> ProtectionChange {
        switch self {
        case .safeBrowsing: .safeBrowsing(isOn)
        case .parentalControl: .parentalControl(isOn)
        case .safeSearch: .safeSearch(isOn)
        }
    }

    /// The value requested by `change` for this feature, if it concerns it.
    func requestedValue(in change: ProtectionChange) -> Bool? {
        switch (self, change) {
        case let (.safeBrowsing, .safeBrowsing(isOn)),
             let (.parentalControl, .parentalControl(isOn)),
             let (.safeSearch, .safeSearch(isOn)):
            isOn
        default:
            nil
        }
    }
}
