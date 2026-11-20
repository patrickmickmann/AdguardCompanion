import SwiftUI

/// Blocklists and allowlists: switch, add, remove and refresh.
struct FilterListsScreen: View {
    @State private var model: FilterListsModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: FilterListsModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Filterlisten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .task { await model.load() }
            .sheet(item: $model.addingKind) { kind in
                AddFilterListSheet(kind: kind, model: model)
            }
            .confirmationDialog(
                "Filterliste entfernen?", isPresented: isConfirmingRemoval,
                titleVisibility: .visible, presenting: model.listPendingRemoval
            ) { list in
                Button("Entfernen", role: .destructive) { Task { await model.apply(.remove(list)) } }
            } message: { list in
                Text("„\(list.name)“ wird vom Server entfernt. Du kannst sie später über ihre Adresse wieder hinzufügen.")
            }
            .alert(model.actionError?.title ?? "", isPresented: hasActionError, presenting: model.actionError) { _ in
                Button("OK") { model.actionError = nil }
            } message: { error in
                Text(error.message)
            }
            .alert("Filterlisten aktualisiert", isPresented: hasRefreshResult, presenting: model.refreshedCount) { _ in
                Button("OK") { model.refreshedCount = nil }
            } message: { count in
                Text(count == 0 ? "Alle Listen wurden geprüft und waren bereits aktuell." : "\(count) Listen hatten neue Regeln.")
            }
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
                    Toggle("Filterlisten anwenden", isOn: filteringBinding)
                        .disabled(model.isWorking)
                } footer: {
                    Text("Ausgeschaltet wendet AdGuard Home weder Filterlisten noch eigene Regeln an. Aktualisiert wird alle \(settings.updateIntervalHours) Stunden.")
                }
                ForEach(FilterList.Kind.allCases) { kind in
                    listSection(kind, lists: settings.lists(of: kind))
                }
            }
            .refreshable { await model.load() }
        } else if let error = model.loadError {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.load() } }
                    .buttonStyle(.glassProminent)
            }
        } else {
            ProgressView()
        }
    }

    private func listSection(_ kind: FilterList.Kind, lists: [FilterList]) -> some View {
        Section {
            if lists.isEmpty {
                Text("Keine \(kind.title)").foregroundStyle(.secondary)
            }
            ForEach(lists) { list in
                FilterListRow(list: list, model: model)
            }
        } header: {
            Text(kind.title)
        } footer: {
            Text(kind.footer)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if model.isRefreshing {
                ProgressView().accessibilityLabel("Filterlisten werden aktualisiert")
            } else {
                Button("Aktualisieren", systemImage: "arrow.clockwise") { Task { await model.refreshLists() } }
                    .disabled(model.settings == nil || model.isWorking)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("Hinzufügen", systemImage: "plus") {
                ForEach(FilterList.Kind.allCases) { kind in
                    Button(kind.addTitle) { model.addingKind = kind }
                }
            }
            .disabled(model.settings == nil || model.isWorking)
        }
    }

    private var filteringBinding: Binding<Bool> {
        Binding { model.isFilteringOn } set: { isOn in
            Task { await model.apply(.setFilteringEnabled(isOn)) }
        }
    }

    private var isConfirmingRemoval: Binding<Bool> {
        Binding { model.listPendingRemoval != nil } set: { if !$0 { model.listPendingRemoval = nil } }
    }

    private var hasActionError: Binding<Bool> {
        Binding { model.actionError != nil } set: { if !$0 { model.actionError = nil } }
    }

    private var hasRefreshResult: Binding<Bool> {
        Binding { model.refreshedCount != nil } set: { if !$0 { model.refreshedCount = nil } }
    }
}
