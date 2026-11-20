import SwiftUI

/// Connection management, connection test and server information.
struct SettingsScreen: View {
    let connection: ActiveConnection

    @Environment(AppModel.self) private var appModel
    @State private var testModel: ConnectionTestModel
    @State private var confirmsDisconnect = false
    @State private var disconnectFailed = false

    init(connection: ActiveConnection) {
        self.connection = connection
        _testModel = State(initialValue: ConnectionTestModel(repository: connection.repository))
    }

    var body: some View {
        List {
            ServerIdentitySection(connection: connection, testModel: testModel)
            if !connection.isDemo {
                ConnectionSection(connection: connection, testModel: testModel)
            }
            if let status = testModel.status {
                ServerInfoSection(status: status, isDemo: connection.isDemo)
            }
            Section {
                Button(disconnectTitle, role: .destructive) { confirmsDisconnect = true }
                    // Anchored to the button so the popover points at its source.
                    .confirmationDialog(disconnectTitle, isPresented: $confirmsDisconnect) {
                        Button(disconnectTitle, role: .destructive, action: disconnect)
                    } message: {
                        Text(connection.isDemo
                             ? "Die Beispieldaten werden ausgeblendet."
                             : "Serveradresse und Zugangsdaten werden von diesem iPhone entfernt.")
                    }
            } footer: {
                Text(connection.isDemo
                     ? "Beendet den Demo-Modus und führt zurück zur Einrichtung."
                     : "Entfernt Serveradresse und Zugangsdaten von diesem iPhone. Am Server wird nichts verändert.")
            }
        }
        .navigationTitle("Einstellungen")
        .task { await testModel.run() }
        .alert("Trennen fehlgeschlagen", isPresented: $disconnectFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Die Zugangsdaten konnten nicht aus dem Schlüsselbund entfernt werden.")
        }
    }

    private var disconnectTitle: LocalizedStringKey {
        connection.isDemo ? "Demo-Modus beenden" : "Verbindung trennen"
    }

    private func disconnect() {
        do {
            try appModel.disconnect()
        } catch {
            disconnectFailed = true
        }
    }
}
