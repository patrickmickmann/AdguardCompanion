import SwiftUI

/// The five primary areas of the app.
enum AppTab: String, CaseIterable, Identifiable {
    case overview, activity, clients, protection, settings

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .overview: "Overview"
        case .activity: "Activity"
        case .clients: "Clients"
        case .protection: "Protection"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "house"
        case .activity: "chart.bar.xaxis"
        case .clients: "laptopcomputer.and.iphone"
        case .protection: "checkmark.shield"
        case .settings: "gearshape"
        }
    }
}

struct MainTabView: View {
    let connection: ActiveConnection
    @State private var selection: AppTab = .overview

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    NavigationStack {
                        screen(for: tab)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .overview:
            OverviewScreen(repository: connection.repository)
        case .activity:
            FeaturePreviewScreen(feature: .activity)
        case .clients:
            FeaturePreviewScreen(feature: .clients)
        case .protection:
            FeaturePreviewScreen(feature: .protection)
        case .settings:
            SettingsScreen(connection: connection)
        }
    }
}
