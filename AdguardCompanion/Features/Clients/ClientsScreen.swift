import SwiftUI

/// Devices in the network, split into configured and discovered clients.
struct ClientsScreen: View {
    @State private var model: ClientsModel
    @State private var queryLogClient: NetworkClient?

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: ClientsModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Clients")
            .searchable(text: $model.searchText, prompt: "Name oder Adresse")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { ClientSortMenu(selection: $model.sortOrder) }
            }
            .navigationDestination(item: $queryLogClient) { client in
                ActivityScreen(
                    repository: model.repository,
                    initialSearch: QueryLogQuery.exactTerm(client.searchableAddress ?? client.name),
                    title: client.displayTitle
                )
            }
            .task { if !model.hasLoaded { await model.load() } }
    }

    @ViewBuilder
    private var content: some View {
        if model.clients.isEmpty {
            placeholder
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background)
        } else {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                clientSection("Eingerichtet", clients: model.configured,
                              footer: "Clients mit eigenem Namen und eigenen Einstellungen.")
                clientSection("Erkannt", clients: model.discovered,
                              footer: "Von AdGuard Home automatisch erkannte Geräte. Für sie gelten die globalen Einstellungen.")
                if model.configured.isEmpty, model.discovered.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                }
            }
            .refreshable { await model.load() }
        }
    }

    @ViewBuilder
    private func clientSection(_ title: LocalizedStringKey, clients: [NetworkClient],
                               footer: LocalizedStringKey) -> some View {
        if !clients.isEmpty {
            Section {
                ForEach(clients) { client in
                    NavigationLink {
                        ClientDetailScreen(client: client, model: model)
                    } label: {
                        ClientRow(client: client)
                    }
                    .clientRowActions(for: client) { queryLogClient = $0 }
                }
            } header: {
                Text(title)
            } footer: {
                Text(footer)
            }
        }
    }

    @ViewBuilder
    private var placeholder: some View {
        if let error = model.error {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.load() } }
                    .buttonStyle(.glassProminent)
            }
        } else if !model.hasLoaded {
            ProgressView()
        } else {
            ContentUnavailableView(
                "Keine Clients",
                systemImage: "laptopcomputer.and.iphone",
                description: Text("AdGuard Home hat noch keine Geräte erkannt.")
            )
        }
    }
}
