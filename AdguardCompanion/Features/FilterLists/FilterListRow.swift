import SwiftUI
import UIKit

/// One filter list with its switch, rule count and last update.
struct FilterListRow: View {
    let list: FilterList
    let model: FilterListsModel

    var body: some View {
        Toggle(isOn: binding) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(list.name)
                    .foregroundStyle(model.isOn(list) ? .primary : .secondary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(model.isWorking)
        .swipeActions(edge: .trailing) {
            Button("Entfernen", systemImage: "trash", role: .destructive) {
                model.listPendingRemoval = list
            }
        }
        .contextMenu {
            Button("Adresse kopieren", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = list.url
            }
            Button("Entfernen", systemImage: "trash", role: .destructive) {
                model.listPendingRemoval = list
            }
        }
    }

    private var detail: String {
        // AdGuard Home reports 0 rules for disabled lists, which would be misleading.
        let rules = list.isEnabled
            ? String(localized: "\(list.ruleCount.formatted()) Regeln")
            : String(localized: "Ausgeschaltet")
        guard let updated = list.lastUpdated else { return rules }
        return "\(rules) · \(updated.formatted(.relative(presentation: .named)))"
    }

    private var binding: Binding<Bool> {
        Binding {
            model.isOn(list)
        } set: { isOn in
            Task { await model.apply(.setEnabled(list, isOn)) }
        }
    }
}

extension FilterList.Kind: Identifiable {
    var id: Self { self }

    var title: String {
        switch self {
        case .blocklist: "Sperrlisten"
        case .allowlist: "Zulassungslisten"
        }
    }

    var singularTitle: String {
        switch self {
        case .blocklist: "Sperrliste"
        case .allowlist: "Zulassungsliste"
        }
    }

    var addTitle: String {
        switch self {
        case .blocklist: "Sperrliste hinzufügen"
        case .allowlist: "Zulassungsliste hinzufügen"
        }
    }

    var footer: String {
        switch self {
        case .blocklist: "Domains aus Sperrlisten werden blockiert."
        case .allowlist: "Domains aus Zulassungslisten werden nie blockiert, auch wenn eine Sperrliste sie enthält."
        }
    }
}
