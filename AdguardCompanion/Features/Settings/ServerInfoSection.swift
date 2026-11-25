import SwiftUI

/// Read-only information reported by `/control/status`.
struct ServerInfoSection: View {
    let status: ServerStatus
    let isDemo: Bool

    var body: some View {
        Section(isDemo ? "Server (Beispieldaten)" : "Server") {
            SettingsRow("Version", systemImage: "info", color: .gray) {
                Text(status.version ?? "Unbekannt").font(AppFont.technicalSmall)
            }
            SettingsRow("DNS-Server", systemImage: "network", color: AppColor.network) {
                Text(status.isDNSRunning ? "Läuft" : "Gestoppt")
            }
            if !status.dnsAddresses.isEmpty {
                NavigationLink {
                    DNSAddressesScreen(addresses: status.dnsAddresses)
                } label: {
                    SettingsRow("DNS-Adressen", systemImage: "point.3.connected.trianglepath.dotted",
                                color: AppColor.performance) {
                        Text(status.dnsAddresses.count.formatted())
                    }
                }
            }
            if let port = status.dnsPort {
                SettingsRow("DNS-Port", systemImage: "number", color: Color(uiColor: .systemIndigo)) {
                    Text(String(port)).font(AppFont.technicalSmall)
                }
            }
            if let startedAt = status.startedAt {
                SettingsRow("Gestartet", systemImage: "clock.fill", color: AppColor.warning) {
                    Text(startedAt.formatted(.relative(presentation: .named)))
                }
            }
        }
    }
}
