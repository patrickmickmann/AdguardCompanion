import SwiftUI

/// Links to the server-side configuration screens.
struct ServerConfigurationSection: View {
    let repository: any AdGuardRepository

    var body: some View {
        Section {
            IconNavigationLink("DNS", systemImage: "server.rack", color: AppColor.network) { DNSSettingsScreen(repository: repository) }
            IconNavigationLink("Query-Log", systemImage: "list.bullet.rectangle.fill", color: .gray) {
                LogSettingsScreen(kind: .queryLog, repository: repository)
            }
            IconNavigationLink("Statistik", systemImage: "chart.bar.fill", color: AppColor.performance) {
                LogSettingsScreen(kind: .statistics, repository: repository)
            }
            IconNavigationLink("Verschlüsselung", systemImage: "lock.fill", color: AppColor.protection) { TLSStatusScreen(repository: repository) }
        } header: {
            Text("AdGuard Home konfigurieren")
        } footer: {
            Text("Änderungen gelten sofort für alle Geräte im Netzwerk.")
        }
    }
}
