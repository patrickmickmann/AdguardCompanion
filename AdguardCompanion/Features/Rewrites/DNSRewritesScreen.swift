import SwiftUI

/// DNS rewrites: answer chosen domains with a fixed address or name.
struct DNSRewritesScreen: View {
    @State private var model: DNSRewritesModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: DNSRewritesModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("DNS-Rewrites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Rewrite hinzufügen", systemImage: "plus") { model.editing = .new }
                        .disabled(model.settings == nil || model.isWorking)
                }
            }
            .task { await model.load() }
            .sheet(item: $model.editing) { editing in
                DNSRewriteEditor(editing: editing, model: model)
            }
            .confirmationDialog("Rewrite entfernen?", isPresented: isConfirmingRemoval,
                                titleVisibility: .visible, presenting: model.rewritePendingRemoval) { rewrite in
                Button("Entfernen", role: .destructive) { Task { await model.apply(.remove(rewrite)) } }
            } message: { rewrite in
                Text("\(rewrite.domain) → \(rewrite.answer)")
            }
            .apiErrorAlert($model.actionError)
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    @ViewBuilder
    private var content: some View {
        if let settings = model.settings {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                Section {
                    Toggle("Rewrites anwenden", isOn: globalBinding).disabled(model.isWorking)
                } footer: {
                    Text("Ein Rewrite beantwortet Anfragen für eine Domain direkt mit einer festen Adresse, etwa für Geräte im Heimnetz.")
                }
                Section("Rewrites") {
                    if settings.rewrites.isEmpty {
                        Text("Keine Rewrites").foregroundStyle(.secondary)
                    }
                    ForEach(settings.rewrites) { rewrite in
                        row(rewrite)
                    }
                }
            }
            .refreshable { await model.load() }
        } else {
            LoadStateView(error: model.loadError) { await model.load() }
        }
    }

    private func row(_ rewrite: DNSRewrite) -> some View {
        Toggle(isOn: binding(for: rewrite)) {
            Button {
                model.editing = .existing(rewrite)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(rewrite.domain).foregroundStyle(model.isOn(rewrite) ? .primary : .secondary)
                    Label(rewrite.answer, systemImage: "arrow.turn.down.right")
                        .font(AppFont.technicalSmall)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .disabled(model.isWorking)
        .swipeActions(edge: .trailing) {
            Button("Entfernen", systemImage: "trash", role: .destructive) { model.rewritePendingRemoval = rewrite }
        }
    }

    private func binding(for rewrite: DNSRewrite) -> Binding<Bool> {
        Binding { model.isOn(rewrite) } set: { isOn in
            let updated = DNSRewrite(domain: rewrite.domain, answer: rewrite.answer, isEnabled: isOn)
            Task { await model.apply(.update(rewrite, to: updated)) }
        }
    }

    private var globalBinding: Binding<Bool> {
        Binding { model.areRewritesOn } set: { isOn in Task { await model.apply(.setRewritesEnabled(isOn)) } }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding { model.rewritePendingRemoval != nil } set: { if !$0 { model.rewritePendingRemoval = nil } }
    }
}
