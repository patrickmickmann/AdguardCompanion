import SwiftUI
import UIKit

/// Read-only quick actions for a query row: narrowing the log and copying.
/// Actions that change server rules are intentionally not offered here yet.
private struct QueryRowActions: ViewModifier {
    let entry: QueryLogEntry
    let model: ActivityModel

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                Button {
                    model.search(for: QueryLogQuery.exactTerm(entry.domain))
                } label: {
                    Label("Domain anzeigen", systemImage: "line.3.horizontal.decrease")
                }
                .tint(AppColor.network)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    UIPasteboard.general.string = entry.domain
                } label: {
                    Label("Kopieren", systemImage: "doc.on.doc")
                }
                .tint(.gray)
            }
            .contextMenu {
                Section {
                    Button("Nur diese Domain anzeigen", systemImage: "globe") {
                        model.search(for: QueryLogQuery.exactTerm(entry.domain))
                    }
                    if !entry.client.address.isEmpty {
                        Button("Nur dieses Gerät anzeigen", systemImage: "desktopcomputer") {
                            model.search(for: QueryLogQuery.exactTerm(entry.client.address))
                        }
                    }
                }
                Section {
                    Button("Domain kopieren", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = entry.domain
                    }
                    if !entry.client.address.isEmpty {
                        Button("IP-Adresse kopieren", systemImage: "number") {
                            UIPasteboard.general.string = entry.client.address
                        }
                    }
                }
            }
    }
}

extension View {
    func queryRowActions(for entry: QueryLogEntry, model: ActivityModel) -> some View {
        modifier(QueryRowActions(entry: entry, model: model))
    }
}
