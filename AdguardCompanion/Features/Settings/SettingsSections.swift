import SwiftUI

/// Connection parameters and the connection test result.
struct ConnectionSection: View {
    let connection: ActiveConnection
    let testModel: ConnectionTestModel

    var body: some View {
        Section("Verbindung") {
            if let configuration = connection.configuration {
                LabeledContent("Server") {
                    Text(configuration.baseURL.absoluteString)
                        .font(AppFont.technicalSmall)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                LabeledContent("Benutzer", value: configuration.username)
                if ServerAddress.isInsecure(configuration.baseURL) {
                    Label("Unverschlüsselt (HTTP)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColor.warning)
                }
            } else {
                LabeledContent("Modus", value: "Demo mit Beispieldaten")
                LabeledContent("Status") { StatusLabel(text: "Keine Serververbindung", tone: .neutral) }
            }
            // A connection test is only meaningful against a real server.
            if !connection.isDemo {
                testRow
                Button("Verbindung testen") { Task { await testModel.run() } }
                    .disabled(testModel.state == .testing)
            }
        }
        .listRowBackground(AppColor.surface)
    }

    @ViewBuilder
    private var testRow: some View {
        switch testModel.state {
        case .idle:
            EmptyView()
        case .testing:
            LabeledContent("Status") { ProgressView() }
        case let .succeeded(_, latency):
            LabeledContent("Status") {
                StatusLabel(
                    text: "Verbunden · \(latency.formatted(.units(allowed: [.milliseconds], width: .abbreviated)))",
                    tone: .positive
                )
            }
        case let .failed(error):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                StatusLabel(text: error.title, tone: .critical)
                Text(error.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Read-only information reported by `/control/status`.
struct ServerInfoSection: View {
    let status: ServerStatus
    let isDemo: Bool

    var body: some View {
        Section(isDemo ? "Server (Beispieldaten)" : "Server") {
            LabeledContent("Version") {
                Text(status.version ?? "Unbekannt").font(AppFont.technicalSmall)
            }
            LabeledContent("DNS-Server", value: status.isDNSRunning ? "Läuft" : "Gestoppt")
            if !status.dnsAddresses.isEmpty {
                LabeledContent("DNS-Adressen") {
                    Text(status.dnsAddresses.joined(separator: ", ")).font(AppFont.technicalSmall)
                }
            }
            if let port = status.dnsPort {
                LabeledContent("DNS-Port") { Text(String(port)).font(AppFont.technicalSmall) }
            }
            if let startedAt = status.startedAt {
                LabeledContent("Gestartet", value: startedAt.formatted(.relative(presentation: .named)))
            }
        }
        .listRowBackground(AppColor.surface)
    }
}
