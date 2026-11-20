import SwiftUI

/// Query log with native search, a filter menu and endless scrolling.
struct ActivityScreen: View {
    @State private var model: ActivityModel
    private let title: String?

    /// - Parameters:
    ///   - initialSearch: Pre-filled search, e.g. a client's IP address.
    ///   - title: Title when opened for a specific device; the search field is
    ///     then kept visible so the active filter is always apparent.
    init(repository: any AdGuardRepository, initialSearch: String = "", title: String? = nil) {
        let model = ActivityModel(repository: repository)
        model.searchText = initialSearch
        _model = State(initialValue: model)
        self.title = title
    }

    var body: some View {
        content
            .navigationTitle(title ?? String(localized: "Aktivität"))
            .searchable(
                text: $model.searchText,
                placement: .navigationBarDrawer(displayMode: title == nil ? .automatic : .always),
                prompt: "Domain oder Client-IP"
            )
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
