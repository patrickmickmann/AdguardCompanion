import SwiftUI

/// Encryption settings of the server, read only.
struct TLSStatusScreen: View {
    let repository: any AdGuardRepository
    @State private var status: TLSStatus?
    @State private var error: APIError?

    var body: some View {
        content
            .navigationTitle("Verschlüsselung")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let status {
            List {
                Section {
                    LabeledContent("Verschlüsselung", value: status.isEnabled ? String(localized: "Ein") : String(localized: "Aus"))
                    if let name = status.serverName { LabeledContent("Servername", value: name) }
                    if status.isEnabled {
                        LabeledContent("HTTPS erzwingen", value: status.forcesHTTPS ? String(localized: "Ja") : String(localized: "Nein"))
                    }
                } footer: {
                    Text("Zertifikate und Ports änderst du in der Weboberfläche von AdGuard Home. Eine falsche Einstellung könnte die Verbindung dieser App unterbrechen.")
                }
                if status.isEnabled {
                    Section("Ports") {
                        port("HTTPS", status.httpsPort)
                        port("DNS-over-TLS", status.dnsOverTLSPort)
                        port("DNS-over-QUIC", status.dnsOverQUICPort)
                    }
                    Section("Zertifikat") {
                        LabeledContent("Gültig", value: status.isCertificateValid ? String(localized: "Ja") : String(localized: "Nein"))
                        if let subject = status.subject { LabeledContent("Inhaber", value: subject) }
                        if let issuer = status.issuer { LabeledContent("Aussteller", value: issuer) }
                        if let expiry = status.expiresAt {
                            LabeledContent("Läuft ab", value: expiry.formatted(date: .abbreviated, time: .omitted))
                        }
                        ForEach(status.dnsNames, id: \.self) { Text($0).font(AppFont.technicalSmall) }
                    }
                }
            }
            .refreshable { await load() }
        } else {
            LoadStateView(error: error) { await load() }
        }
    }

    @ViewBuilder
    private func port(_ title: String, _ value: Int?) -> some View {
        LabeledContent(title, value: value.map { String($0) } ?? String(localized: "Aus"))
    }

    private func load() async {
        do {
            status = try await repository.fetchTLSStatus()
            error = nil
        } catch {
            guard error != .cancelled else { return }
            self.error = error
        }
    }
}
