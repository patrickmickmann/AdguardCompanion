import SwiftUI

/// Query log with native search, a filter menu and endless scrolling.
struct ActivityScreen: View {
    @State private var model: ActivityModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: ActivityModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Aktivität")
            .searchable(text: $model.searchText, prompt: "Domain oder Client-IP")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { QueryFilterMenu(selection: $model.filter) }
            }
            .task(id: model.queryKey) { await model.loadIfNeeded() }
            .sensoryFeedback(.selection, trigger: model.filter)
    }

    @ViewBuilder
    private var content: some View {
        if model.entries.isEmpty {
            emptyState
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background)
        } else {
            QueryList(model: model)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if let error = model.error {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.reload() } }
                    .buttonStyle(.glassProminent)
            }
        } else if !model.hasLoaded || model.isLoading {
            ProgressView()
        } else if !model.queryKey.search.isEmpty {
            ContentUnavailableView.search(text: model.queryKey.search)
        } else {
            ContentUnavailableView(
                "Keine Anfragen",
                systemImage: "list.bullet.rectangle",
                description: Text(model.filter == .all
                    ? "Das Query-Log ist leer oder deaktiviert."
                    : "Für diesen Filter gibt es keine Einträge.")
            )
        }
    }
}
