import SwiftUI

/// The three upstream lists that can be edited.
enum UpstreamKind: String, CaseIterable, Identifiable {
    case upstreams = "upstream_dns", bootstrap = "bootstrap_dns", fallback = "fallback_dns"

    var id: Self { self }

    var title: String {
        switch self {
        case .upstreams: "Upstream-DNS"
        case .bootstrap: "Bootstrap-DNS"
        case .fallback: "Fallback-DNS"
        }
    }

    var footer: String {
        switch self {
        case .upstreams:
            "Ein Server pro Zeile, z. B. https://dns.quad9.net/dns-query, tls://1.1.1.1 oder 9.9.9.9. [/example.org/]1.1.1.1 gilt nur für eine Domain. Zeilen mit # sind Kommentare."
        case .bootstrap: "IP-Adressen, mit denen AdGuard Home die Namen der verschlüsselten Upstream-Server auflöst."
        case .fallback: "Werden gefragt, wenn kein Upstream-Server antwortet. Leer bedeutet: keine."
        }
    }

    func lines(in set: UpstreamSet) -> [String] {
        switch self {
        case .upstreams: set.upstreams
        case .bootstrap: set.bootstrap
        case .fallback: set.fallback
        }
    }
}

/// Edits one upstream list. Saving first lets AdGuard Home test the
/// servers; failures are shown and must be confirmed before saving anyway.
struct UpstreamEditorScreen: View {
    let kind: UpstreamKind
    let model: DNSSettingsModel
    @State private var text = ""
    @State private var failures: [String: String] = [:]
    @State private var isTesting = false
    @State private var confirmsFailures = false
    @Environment(\.dismiss) private var dismiss

    private var lines: [String] { UpstreamSet.lines(from: text) }
    private var savedLines: [String] { model.settings.map { kind.lines(in: $0.upstreams) } ?? [] }
    private var isBusy: Bool { isTesting || model.isWorking }

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .font(AppFont.technicalSmall)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .frame(minHeight: 160)
            } footer: {
                Text(kind.footer)
            }
            if !failures.isEmpty {
                Section("Nicht erreichbar") {
                    ForEach(failures.sorted { $0.key < $1.key }, id: \.key) { server, message in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(server).font(AppFont.technicalSmall)
                            Text(message).font(.footnote).foregroundStyle(AppColor.blocked)
                        }
                    }
                }
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isBusy {
                    ProgressView()
                } else {
                    Button("Sichern", role: .confirm) { Task { await testAndSave() } }
                        .disabled(lines == savedLines || (kind == .upstreams && UpstreamSet.effective(lines).isEmpty))
                }
            }
        }
        .onAppear { text = savedLines.joined(separator: "\n") }
        .confirmationDialog("Trotzdem sichern?", isPresented: $confirmsFailures, titleVisibility: .visible) {
            Button("Trotzdem sichern", role: .destructive) { Task { await save() } }
        } message: {
            Text("\(failures.count) Server haben den Test nicht bestanden. Fehlerhafte Upstreams können die Namensauflösung im ganzen Netz stören.")
        }
        .interactiveDismissDisabled(isBusy)
    }

    private func testAndSave() async {
        guard var set = model.settings?.upstreams else { return }
        switch kind {
        case .upstreams: set.upstreams = lines
        case .bootstrap: set.bootstrap = lines
        case .fallback: set.fallback = lines
        }
        isTesting = true
        defer { isTesting = false }
        do {
            let results = try await model.repository.testUpstreams(set)
            failures = results.filter { $0.value != "OK" }
            if failures.isEmpty { await save() } else { confirmsFailures = true }
        } catch {
            model.actionError = error
        }
    }

    private func save() async {
        if await model.apply([kind.rawValue: .array(lines.map(JSONValue.string))]) { dismiss() }
    }
}
