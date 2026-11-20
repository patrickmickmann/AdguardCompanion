import SwiftUI

/// Query log or statistics configuration: recording, retention, privacy,
/// excluded domains and deleting the collected data.
struct LogSettingsScreen: View {
    @State private var model: LogSettingsModel

    init(kind: LogKind, repository: any AdGuardRepository) {
        _model = State(initialValue: LogSettingsModel(kind: kind, repository: repository))
    }

    private var texts: LogKindTexts { LogKindTexts(kind: model.kind) }

    var body: some View {
        content
            .navigationTitle(texts.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.load() }
            .confirmationDialog(texts.clearTitle, isPresented: $model.isConfirmingClear, titleVisibility: .visible) {
                Button(texts.clearAction, role: .destructive) { Task { await model.clearData() } }
            } message: {
                Text(texts.clearMessage)
            }
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
                    Toggle(texts.enabledTitle, isOn: binding(\.isEnabled))
                    Picker("Aufbewahren", selection: binding(\.retention)) {
                        ForEach(settings.retentionChoices, id: \.self) { Text(LogKindTexts.retention($0)).tag($0) }
                    }
                    if settings.anonymizesClientIP != nil {
                        Toggle("IP-Adressen anonymisieren", isOn: anonymizeBinding)
                    }
                } footer: {
                    Text(texts.footer)
                }
                .disabled(model.isWorking)
                LogIgnoredDomainsSection(model: model, settings: settings)
                Section {
                    Button(texts.clearAction, role: .destructive) { model.isConfirmingClear = true }
                        .disabled(model.isWorking)
                }
            }
            .refreshable { await model.load() }
        } else {
            LoadStateView(error: model.loadError) { await model.load() }
        }
    }

    private func binding<Value: Equatable>(_ keyPath: WritableKeyPath<LogSettings, Value>) -> Binding<Value> {
        Binding {
            model.displayed?[keyPath: keyPath] ?? LogSettings(kind: model.kind, document: [:])[keyPath: keyPath]
        } set: { value in
            Task { await model.update { $0[keyPath: keyPath] = value } }
        }
    }

    private var anonymizeBinding: Binding<Bool> {
        Binding { model.displayed?.anonymizesClientIP ?? false } set: { value in
            Task { await model.update { $0.anonymizesClientIP = value } }
        }
    }
}

/// Domains that are not recorded, with add and swipe-to-remove.
private struct LogIgnoredDomainsSection: View {
    @Bindable var model: LogSettingsModel
    let settings: LogSettings

    var body: some View {
        Section {
            if let isOn = settings.isIgnoreListEnabled {
                Toggle("Ausnahmen anwenden", isOn: Binding { isOn } set: { value in
                    Task { await model.update { $0.isIgnoreListEnabled = value } }
                })
            }
            ForEach(settings.ignoredDomains, id: \.self) { domain in
                Text(domain)
                    .font(AppFont.technicalSmall)
                    .swipeActions(edge: .trailing) {
                        Button("Entfernen", systemImage: "trash", role: .destructive) {
                            Task { await model.update { $0.ignoredDomains.removeAll { $0 == domain } } }
                        }
                    }
            }
            HStack {
                TextField("Domain hinzufügen", text: $model.newIgnoredDomain)
                    .font(AppFont.technicalSmall)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onSubmit { Task { await model.addIgnoredDomain() } }
                Button("Hinzufügen", systemImage: "plus.circle.fill") { Task { await model.addIgnoredDomain() } }
                    .labelStyle(.iconOnly)
                    .disabled(!model.canAddIgnoredDomain)
            }
        } header: {
            Text("Ausgenommene Domains")
        } footer: {
            Text("Anfragen an diese Domains werden nicht erfasst. *.example.org gilt für alle Subdomains.")
        }
        .disabled(model.isWorking)
    }
}
