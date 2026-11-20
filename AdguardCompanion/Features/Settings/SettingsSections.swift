import SwiftUI

/// Prominent first row, like the Apple Account row in the Settings app.
struct ServerIdentitySection: View {
    let connection: ActiveConnection
    let testModel: ConnectionTestModel

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 56

    var body: some View {
        Section {
            HStack(spacing: Spacing.l) {
                Image(systemName: "server.rack")
                    .font(.system(size: iconSize * 0.45, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: iconSize, height: iconSize)
                    .background(AppColor.protection.gradient, in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(connection.isDemo ? "Demo-Server" : "AdGuard Home")
                        .font(.title3.weight(.semibold))
                    Text(connection.configuration?.baseURL.host() ?? "Beispieldaten")
                        .font(connection.isDemo ? .footnote : AppFont.technicalSmall)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    statusLabel
                }
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if connection.isDemo {
            StatusLabel(text: "Keine Serververbindung", tone: .neutral)
        } else {
            switch testModel.state {
            case .idle, .testing:
                StatusLabel(text: "Wird geprüft …", tone: .neutral)
            case let .succeeded(_, latency):
                StatusLabel(text: "Verbunden · \(latency.formattedMilliseconds) ms", tone: .positive)
            case let .failed(error):
                StatusLabel(text: error.title, tone: .critical)
            }
        }
    }
}

/// Connection parameters and the connection test action.
struct ConnectionSection: View {
    let connection: ActiveConnection
    let testModel: ConnectionTestModel

    var body: some View {
        Section {
            if let configuration = connection.configuration {
                SettingsRow("Adresse", systemImage: "link", color: AppColor.network) {
                    Text(configuration.baseURL.absoluteString)
                        .font(AppFont.technicalSmall)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                SettingsRow("Benutzer", systemImage: "person.fill", color: .gray) {
                    Text(configuration.username)
                }
                if ServerAddress.isInsecure(configuration.baseURL) {
                    SettingsRow("Unverschlüsselt (HTTP)", systemImage: "exclamationmark.triangle.fill",
                                color: AppColor.warning) { EmptyView() }
                }
            }
            if case let .failed(error) = testModel.state {
                Text(error.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Button {
                Task { await testModel.run() }
            } label: {
                SettingsRow("Verbindung testen", systemImage: "checkmark.seal.fill", color: AppColor.protection) {
                    if testModel.state == .testing { ProgressView() }
                }
            }
            .disabled(testModel.state == .testing)
        } header: {
            Text("Verbindung")
        }
    }
}

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
