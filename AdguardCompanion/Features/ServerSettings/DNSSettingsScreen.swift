import SwiftUI

/// Upstream servers, resolution behavior, DNSSEC and cache.
struct DNSSettingsScreen: View {
    @State private var model: DNSSettingsModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: DNSSettingsModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("DNS")
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.load() }
            .apiErrorAlert($model.actionError)
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    @ViewBuilder
    private var content: some View {
        if let settings = model.displayed {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                Section {
                    ForEach(UpstreamKind.allCases) { kind in
                        NavigationLink {
                            UpstreamEditorScreen(kind: kind, model: model)
                        } label: {
                            LabeledContent(kind.title,
                                           value: UpstreamSet.effective(kind.lines(in: settings.upstreams)).count.formatted())
                        }
                    }
                    Picker("Modus", selection: modeBinding) {
                        ForEach(DNSSettings.UpstreamMode.allCases, id: \.self) { Text($0.title).tag(Optional($0)) }
                    }
                } header: {
                    Text("Upstream-Server")
                } footer: {
                    Text(settings.upstreamMode?.explanation ?? "")
                }
                Section {
                    Toggle("DNSSEC", isOn: toggle("dnssec_enabled", settings.isDNSSECEnabled))
                    Toggle("IPv6-Antworten unterdrücken", isOn: toggle("disable_ipv6", settings.isIPv6Disabled))
                    LabeledContent("Anfragen pro Sekunde und Client",
                                   value: settings.rateLimit == 0 ? String(localized: "Unbegrenzt") : settings.rateLimit.formatted())
                } footer: {
                    Text("DNSSEC lässt AdGuard Home signierte Antworten anfordern. Ohne IPv6-Antworten erhalten Geräte nur IPv4-Adressen.")
                }
                Section {
                    Toggle("Cache", isOn: cacheBinding(settings))
                    Toggle("Optimistisches Caching", isOn: toggle("cache_optimistic", settings.isOptimisticCacheEnabled))
                        .disabled(!settings.isCacheEnabled)
                    LabeledContent("Größe", value: Int64(settings.cacheSize).formatted(.byteCount(style: .memory)))
                } header: {
                    Text("Cache")
                } footer: {
                    Text("Optimistisches Caching beantwortet abgelaufene Einträge sofort und aktualisiert sie im Hintergrund.")
                }
            }
            .disabled(model.isWorking)
            .refreshable { await model.load() }
        } else {
            LoadStateView(error: model.loadError) { await model.load() }
        }
    }

    private func toggle(_ key: String, _ value: Bool) -> Binding<Bool> {
        Binding { value } set: { isOn in Task { await model.apply([key: .bool(isOn)]) } }
    }

    private func cacheBinding(_ settings: DNSSettings) -> Binding<Bool> {
        Binding { settings.isCacheEnabled } set: { isOn in
            Task { await model.apply(DNSSettingsUpdater.cachePatch(enabled: isOn, current: settings)) }
        }
    }

    private var modeBinding: Binding<DNSSettings.UpstreamMode?> {
        Binding { model.displayed?.upstreamMode } set: { mode in
            guard let mode else { return }
            Task { await model.apply(["upstream_mode": .string(mode.rawValue)]) }
        }
    }
}

extension DNSSettings.UpstreamMode {
    var title: String {
        switch self {
        case .loadBalance: "Lastverteilung"
        case .parallel: "Parallele Anfragen"
        case .fastestAddress: "Schnellste IP-Adresse"
        }
    }

    var explanation: String {
        switch self {
        case .loadBalance: "Fragt bevorzugt den Server, der zuletzt am schnellsten geantwortet hat."
        case .parallel: "Fragt alle Server gleichzeitig und nimmt die erste Antwort."
        case .fastestAddress: "Fragt alle Server und wählt die IP-Adresse mit der kürzesten Verbindungszeit."
        }
    }
}
