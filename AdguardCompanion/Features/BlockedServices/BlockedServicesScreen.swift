import SwiftUI

/// Blocks whole services such as YouTube or TikTok for all devices.
struct BlockedServicesScreen: View {
    @State private var model: BlockedServicesModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: BlockedServicesModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Gesperrte Dienste")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Dienst suchen")
            .task { await model.load() }
            .apiErrorAlert($model.actionError)
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    @ViewBuilder
    private var content: some View {
        if let services = model.services {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                if model.searchText.isEmpty {
                    Section {
                        if services.blocked.isEmpty {
                            Text("Keine Dienste gesperrt").foregroundStyle(.secondary)
                        }
                        ForEach(services.blocked) { service in
                            Toggle(service.name, isOn: binding(for: service)).disabled(model.isWorking)
                        }
                    } header: {
                        Text("Gesperrt (\(model.blockedCount))")
                    } footer: {
                        Text("Gilt für alle Geräte, die die globalen Einstellungen verwenden. Ein in AdGuard Home eingerichteter Zeitplan bleibt erhalten.")
                    }
                }
                ForEach(services.groups(matching: model.searchText), id: \.id) { group in
                    Section(BlockedServiceGroup.title(group.id)) {
                        ForEach(group.services) { service in
                            Toggle(service.name, isOn: binding(for: service))
                                .disabled(model.isWorking)
                        }
                    }
                }
            }
            .refreshable { await model.load() }
        } else {
            LoadStateView(error: model.loadError) { await model.load() }
        }
    }

    private func binding(for service: BlockableService) -> Binding<Bool> {
        Binding { model.isBlocked(service) } set: { isBlocked in
            Task { await model.setBlocked(service, isBlocked) }
        }
    }
}
