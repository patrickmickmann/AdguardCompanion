import SwiftUI

/// Shows whether a user rule blocks or allows the domain and offers to change it.
/// Every change is confirmed first, because it applies to the whole network.
struct DomainRuleSection: View {
    let model: DomainRuleModel

    var body: some View {
        Section {
            stateRow
            ForEach(model.availableChanges, id: \.self) { change in
                Button(role: change.buttonRole) {
                    model.pendingChange = change
                } label: {
                    Label(change.actionTitle, systemImage: change.systemImage)
                        .foregroundStyle(change.tint)
                }
                .disabled(model.isWorking)
            }
        } header: {
            Text("Eigene Regel")
        } footer: {
            Text("Eigene Regeln gelten für alle Geräte im Netzwerk. Geräte können frühere Antworten noch kurz zwischenspeichern.")
        }
    }

    @ViewBuilder
    private var stateRow: some View {
        if let error = model.loadError {
            LabeledContent("Status") {
                Button("Erneut laden") { Task { await model.load() } }
            }
            Text(error.message).font(.footnote).foregroundStyle(.secondary)
        } else {
            LabeledContent("Status") {
                if model.isWorking || model.status == nil {
                    ProgressView()
                } else if let state = model.status?.state {
                    Text(state.title).foregroundStyle(state.tint)
                }
            }
            if let rule = model.status?.rule {
                Text(rule)
                    .font(AppFont.technicalSmall)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}

/// Confirmation and error presentation for `DomainRuleSection`. Applied to the
/// containing list, because dialogs attached to list sections do not present.
private struct DomainRuleDialogs: ViewModifier {
    @Bindable var model: DomainRuleModel

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                model.pendingChange?.confirmationTitle ?? "",
                isPresented: isConfirming,
                titleVisibility: .visible,
                presenting: model.pendingChange
            ) { change in
                Button(change.actionTitle, role: change.buttonRole) {
                    Task { await model.perform(change) }
                }
            } message: { change in
                Text(change.confirmationMessage)
            }
            .alert(model.actionError?.title ?? "", isPresented: hasActionError, presenting: model.actionError) { _ in
                Button("OK") { model.dismissActionError() }
            } message: { error in
                Text(error.message)
            }
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    private var isConfirming: Binding<Bool> {
        Binding { model.pendingChange != nil } set: { if !$0 { model.pendingChange = nil } }
    }

    private var hasActionError: Binding<Bool> {
        Binding { model.actionError != nil } set: { if !$0 { model.dismissActionError() } }
    }
}

extension View {
    func domainRuleDialogs(_ model: DomainRuleModel) -> some View {
        modifier(DomainRuleDialogs(model: model))
    }
}
