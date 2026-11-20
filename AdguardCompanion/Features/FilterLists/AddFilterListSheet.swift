import SwiftUI

/// Form for subscribing to a new blocklist or allowlist. Closes only after
/// the server confirmed the new list.
struct AddFilterListSheet: View {
    let model: FilterListsModel
    @State private var kind: FilterList.Kind
    @State private var name = ""
    @State private var source = ""
    @Environment(\.dismiss) private var dismiss

    init(kind: FilterList.Kind, model: FilterListsModel) {
        self.model = model
        _kind = State(initialValue: kind)
    }

    private var problem: FilterListInput.Problem? {
        FilterListInput.problem(name: name, source: source, kind: kind, existing: model.settings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Art", selection: $kind) {
                        ForEach(FilterList.Kind.allCases) { Text($0.singularTitle).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section {
                    TextField("Name", text: $name)
                    TextField("https://…", text: $source)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text(footer)
                }
            }
            .navigationTitle("Neue Liste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", role: .cancel) { dismiss() }
                        .disabled(model.isAdding)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isAdding {
                        ProgressView()
                    } else {
                        Button("Hinzufügen", role: .confirm) { add() }
                            .disabled(problem != nil || model.isWorking)
                    }
                }
            }
            .interactiveDismissDisabled(model.isAdding)
        }
        .presentationDetents([.medium, .large])
    }

    private var footer: String {
        switch problem {
        case .duplicate?: "Diese Liste ist bereits eingetragen."
        case .invalidURL? where !source.isEmpty: "Gib eine http- oder https-Adresse oder einen absoluten Dateipfad auf dem Server ein."
        default: "AdGuard Home lädt die Liste sofort herunter. Das kann einige Sekunden dauern."
        }
    }

    private func add() {
        guard let url = FilterListInput.normalizedSource(source) else { return }
        Task {
            if await model.apply(.add(name: name, url: url, kind: kind)) { dismiss() }
        }
    }
}
