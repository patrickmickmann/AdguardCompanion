import SwiftUI
import UIKit

/// Read-only quick actions for a client row: open its query log or copy data.
private struct ClientRowActions: ViewModifier {
    let client: NetworkClient
    let showQueryLog: (NetworkClient) -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                if client.searchableAddress != nil {
                    Button {
                        showQueryLog(client)
                    } label: {
                        Label("Query-Log", systemImage: "list.bullet.rectangle")
                    }
                    .tint(AppColor.network)
                }
            }
            .swipeActions(edge: .trailing) {
                if let address = client.searchableAddress {
                    Button {
                        UIPasteboard.general.string = address
                    } label: {
                        Label("IP kopieren", systemImage: "doc.on.doc")
                    }
                    .tint(.gray)
                }
            }
            .contextMenu {
                if client.searchableAddress != nil {
                    Button("Im Query-Log anzeigen", systemImage: "list.bullet.rectangle") {
                        showQueryLog(client)
                    }
                }
                Section {
                    if client.hasName {
                        Button("Name kopieren", systemImage: "textformat") {
                            UIPasteboard.general.string = client.name
                        }
                    }
                    if let address = client.searchableAddress {
                        Button("IP-Adresse kopieren", systemImage: "number") {
                            UIPasteboard.general.string = address
                        }
                    }
                }
            }
    }
}

extension View {
    func clientRowActions(for client: NetworkClient, showQueryLog: @escaping (NetworkClient) -> Void) -> some View {
        modifier(ClientRowActions(client: client, showQueryLog: showQueryLog))
    }
}

/// Toolbar menu to switch the list order, like the Files app.
struct ClientSortMenu: View {
    @Binding var selection: ClientsModel.SortOrder

    var body: some View {
        Menu {
            Picker("Sortieren nach", selection: $selection) {
                Label("Aktivität", systemImage: "chart.bar").tag(ClientsModel.SortOrder.activity)
                Label("Name", systemImage: "textformat").tag(ClientsModel.SortOrder.name)
            }
        } label: {
            Label("Sortieren", systemImage: "arrow.up.arrow.down")
        }
    }
}
