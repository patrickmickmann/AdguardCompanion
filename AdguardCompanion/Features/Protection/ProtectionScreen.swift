import SwiftUI

/// Server-wide protection: the global switch with pause options and the
/// individual protection features. Every switch shows the server's state.
struct ProtectionScreen: View {
    @State private var model: ProtectionModel
    private let repository: any AdGuardRepository

    init(repository: any AdGuardRepository) {
        self.repository = repository
        _model = State(initialValue: ProtectionModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Schutz")
            .task { await model.load() }
            .task(id: model.pausedUntil) { await model.reloadWhenPauseEnds() }
            .confirmationDialog("Schutz pausieren?", isPresented: $model.isChoosingPause, titleVisibility: .visible) {
                ForEach(ProtectionPause.allCases, id: \.self) { pause in
                    Button(pause.title) { Task { await model.apply(.pauseProtection(pause)) } }
                }
                Button("Bis zum Einschalten ausschalten", role: .destructive) {
                    Task { await model.apply(.disableProtection) }
                }
            } message: {
                Text("Solange der Schutz aus ist, werden Anfragen aller Geräte nicht gefiltert.")
            }
            .alert(model.actionError?.title ?? "", isPresented: hasActionError, presenting: model.actionError) { _ in
                Button("OK") { model.dismissActionError() }
            } message: { error in
                Text(error.message)
            }
            .sensoryFeedback(.success, trigger: model.confirmedChanges)
    }

    @ViewBuilder
    private var content: some View {
        if let settings = model.settings {
            List {
                if model.isDemo {
                    DemoBadge().frame(maxWidth: .infinity).listRowBackground(Color.clear)
                }
                ProtectionStatusSection(settings: settings, model: model)
                ProtectionFeaturesSection(isProtectionOn: settings.protection == .enabled, model: model)
                Section("Filter und Regeln") {
                    IconNavigationLink("Filterlisten", systemImage: "list.bullet.rectangle.fill", color: AppColor.protection) {
                        FilterListsScreen(repository: repository)
                    }
                    IconNavigationLink("Eigene Regeln", systemImage: "text.badge.checkmark", color: AppColor.network) {
                        UserRulesScreen(repository: repository)
                    }
                    IconNavigationLink("Gesperrte Dienste", systemImage: "nosign", color: AppColor.blocked) {
                        BlockedServicesScreen(repository: repository)
                    }
                    IconNavigationLink("DNS-Rewrites", systemImage: "arrow.triangle.branch", color: AppColor.performance) {
                        DNSRewritesScreen(repository: repository)
                    }
                }
            }
            .refreshable { await model.load() }
        } else if let error = model.loadError {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.load() } }
                    .buttonStyle(.glassProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.background)
        }
    }

    private var hasActionError: Binding<Bool> {
        Binding { model.actionError != nil } set: { if !$0 { model.dismissActionError() } }
    }
}

extension ProtectionPause {
    var title: String {
        switch self {
        case .oneMinute: "1 Minute"
        case .tenMinutes: "10 Minuten"
        case .oneHour: "1 Stunde"
        case .eightHours: "8 Stunden"
        case .oneDay: "24 Stunden"
        }
    }
}
