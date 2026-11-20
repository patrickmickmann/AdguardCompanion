import SwiftUI

/// Form for entering the AdGuard Home address and administrator credentials.
struct ConnectionSetupScreen: View {
    @State private var model: ConnectionSetupModel
    @FocusState private var focus: Field?

    private enum Field { case address, username, password }

    init(model: ConnectionSetupModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Form {
            Section {
                TextField("https://adguard.home:3000", text: $model.address)
                    .font(AppFont.technical)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .address)
                    .submitLabel(.next)
                    .onSubmit { focus = .username }
                    .accessibilityLabel("Serveradresse")
            } header: {
                Text("Server")
            } footer: {
                if model.isInsecureAddress {
                    Label("Unverschlüsselte Verbindung. Nutze HTTP nur im eigenen lokalen Netzwerk.",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColor.warning)
                } else {
                    Text("Adresse der AdGuard-Home-Weboberfläche, inklusive Port.")
                }
            }
            .listRowBackground(AppColor.surface)

            Section {
                TextField("Benutzername", text: $model.username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
                SecureField("Passwort", text: $model.password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
            } header: {
                Text("Anmeldung")
            } footer: {
                Text("Zugangsdaten werden ausschließlich im Schlüsselbund dieses iPhones gespeichert.")
            }
            .listRowBackground(AppColor.surface)

            if let failure = model.failure {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(failure.title).font(.headline)
                            Text(failure.message).font(.subheadline).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "xmark.octagon.fill").foregroundStyle(AppColor.blocked)
                    }
                }
                .listRowBackground(AppColor.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle("Verbinden")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) { connectButton }
        .onAppear { focus = .address }
    }

    private var connectButton: some View {
        Button(action: submit) {
            if model.isVerifying {
                ProgressView().tint(AppColor.onProtection)
            } else {
                Text("Verbindung prüfen und speichern")
            }
        }
        .buttonStyle(.primary)
        .disabled(!model.canSubmit)
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.s)
        .accessibilityLabel(model.isVerifying ? "Verbindung wird geprüft" : "Verbindung prüfen und speichern")
    }

    private func submit() {
        focus = nil
        Task { await model.submit() }
    }
}
