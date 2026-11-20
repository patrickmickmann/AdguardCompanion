import SwiftUI

/// Honest placeholder for areas that are not implemented yet.
/// It describes what will be available instead of showing fake data.
struct FeaturePreviewScreen: View {
    enum Feature {
        case clients, protection

        var title: LocalizedStringKey {
            switch self {
            case .clients: "Clients"
            case .protection: "Schutz"
            }
        }

        var systemImage: String {
            switch self {
            case .clients: "laptopcomputer.and.iphone"
            case .protection: "checkmark.shield"
            }
        }

        var headline: LocalizedStringKey {
            switch self {
            case .clients: "Client-Verwaltung in Vorbereitung"
            case .protection: "Schutzfunktionen in Vorbereitung"
            }
        }

        var details: LocalizedStringKey {
            switch self {
            case .clients:
                "Hier siehst du bald alle Geräte im Netzwerk und ihre individuellen Regeln."
            case .protection:
                "Hier verwaltest du bald DNS-Filterung, Filterlisten, eigene Regeln und DNS-Rewrites."
            }
        }
    }

    let feature: Feature

    var body: some View {
        ContentUnavailableView {
            Label(feature.headline, systemImage: feature.systemImage)
        } description: {
            Text(feature.details)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .navigationTitle(feature.title)
    }
}
