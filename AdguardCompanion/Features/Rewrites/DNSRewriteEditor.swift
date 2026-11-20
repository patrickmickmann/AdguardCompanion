import SwiftUI

/// Creates or edits one rewrite. Closes only after the server confirmed it.
struct DNSRewriteEditor: View {
    let editing: DNSRewritesModel.Editing
    let model: DNSRewritesModel
    @State private var domain: String
    @State private var answer: String
    @Environment(\.dismiss) private var dismiss

    init(editing: DNSRewritesModel.Editing, model: DNSRewritesModel) {
        self.editing = editing
        self.model = model
        if case let .existing(rewrite) = editing {
            _domain = State(initialValue: rewrite.domain)
            _answer = State(initialValue: rewrite.answer)
        } else {
            _domain = State(initialValue: "")
            _answer = State(initialValue: "")
        }
    }

    private var existing: DNSRewrite? {
        if case let .existing(rewrite) = editing { rewrite } else { nil }
    }

    private var rewrite: DNSRewrite? {
        DNSRewriteInput.rewrite(domain: domain, answer: answer, isEnabled: existing?.isEnabled ?? true)
    }

    private var isDuplicate: Bool {
        guard let rewrite, existing.map({ !$0.matches(rewrite) }) ?? true else { return false }
        return model.settings?.entry(matching: rewrite) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Domain, z. B. nas.home.arpa", text: $domain)
                    TextField("IP-Adresse oder Domain", text: $answer)
                } footer: {
                    Text(isDuplicate ? "Dieser Rewrite existiert bereits."
                         : "*.example.org gilt für alle Subdomains. Als Antwort sind eine IPv4- oder IPv6-Adresse, eine Domain (CNAME) oder A bzw. AAAA zum Beibehalten der normalen Antwort möglich.")
                }
                .font(AppFont.technical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            }
            .navigationTitle(existing == nil ? "Neuer Rewrite" : "Rewrite bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", role: .cancel) { dismiss() }.disabled(model.isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isWorking {
                        ProgressView()
                    } else {
                        Button("Sichern", role: .confirm) { save() }
                            .disabled(rewrite == nil || isDuplicate || rewrite == existing)
                    }
                }
            }
            .interactiveDismissDisabled(model.isWorking)
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let rewrite else { return }
        let change: DNSRewriteChange = existing.map { .update($0, to: rewrite) } ?? .add(rewrite)
        Task { if await model.apply(change) { dismiss() } }
    }
}
