import SwiftUI
import UIKit

/// The server's user-defined filtering rules: search, add and remove.
struct UserRulesScreen: View {
    @State private var model: UserRulesModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: UserRulesModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Eigene Regeln")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.searchText, prompt: "Regeln durchsuchen")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Regel hinzufügen", systemImage: "plus") { model.isAdding = true }
                        .disabled(model.rules == nil || model.isWorking)
                }
            }
            .task { await model.load() }
            .sheet(isPresented: $model.isAdding) { AddUserRuleSheet(model: model) }
            .confirmationDialog("Regel entfernen?", isPresented: isConfirmingRemoval,
                                titleVisibility: .visible, presenting: model.rulePendingRemoval) { rule in
                Button("Entfernen", role: .destructive) { Task { await model.remove(rule) } }
            } message: { rule in
                Text(rule)
            }
            .apiErrorAlert($model.actionError)
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    @ViewBuilder
    private var content: some View {
        if model.rules != nil {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                Section {
                    if model.visibleRules.isEmpty {
                        Text(model.searchText.isEmpty ? "Keine eigenen Regeln" : "Keine Treffer")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.visibleRules, id: \.self) { rule in
                        ruleRow(rule)
                    }
                } header: {
                    Text("\(model.activeRuleCount) Regeln")
                } footer: {
                    Text("Eigene Regeln gelten für alle Geräte und haben Vorrang vor Filterlisten. Zeilen mit ! oder # sind Kommentare.")
                }
            }
            .refreshable { await model.load() }
        } else {
            LoadStateView(error: model.loadError) { await model.load() }
        }
    }

    private func ruleRow(_ rule: String) -> some View {
        UserRuleRow(rule: rule)
            .swipeActions(edge: .trailing) {
                Button("Entfernen", systemImage: "trash", role: .destructive) { model.rulePendingRemoval = rule }
            }
            .contextMenu {
                Button("Kopieren", systemImage: "doc.on.doc") { UIPasteboard.general.string = rule }
                Button("Entfernen", systemImage: "trash", role: .destructive) { model.rulePendingRemoval = rule }
            }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding { model.rulePendingRemoval != nil } set: { if !$0 { model.rulePendingRemoval = nil } }
    }
}
