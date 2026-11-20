import SwiftUI

/// Form for one new user rule, with the most common rule forms as hints.
/// Closes only after the server confirmed the rule.
struct AddUserRuleSheet: View {
    let model: UserRulesModel
    @State private var rule = ""
    @Environment(\.dismiss) private var dismiss

    private var isValid: Bool { UserRulesUpdater.normalizedRule(rule) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("||example.org^", text: $rule)
                        .font(AppFont.technical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } footer: {
                    Text("Eine Regel pro Eintrag in der AdGuard-Syntax.")
                }
                Section("Beispiele") {
                    example("||example.org^", "Sperrt example.org und Subdomains")
                    example("@@||example.org^", "Erlaubt example.org und Subdomains")
                    example("127.0.0.1 example.org", "Antwortet mit einer festen Adresse")
                    example("! Kommentar", "Wird nicht angewendet")
                }
            }
            .navigationTitle("Neue Regel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", role: .cancel) { dismiss() }.disabled(model.isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isWorking {
                        ProgressView()
                    } else {
                        Button("Hinzufügen", role: .confirm) {
                            Task { if await model.add(rule) { dismiss() } }
                        }
                        .disabled(!isValid)
                    }
                }
            }
            .interactiveDismissDisabled(model.isWorking)
        }
        .presentationDetents([.medium, .large])
    }

    private func example(_ text: String, _ explanation: LocalizedStringKey) -> some View {
        Button {
            rule = text
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(text).font(AppFont.technicalSmall).foregroundStyle(.primary)
                Text(explanation).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
