import SwiftUI

/// "Zuletzt aktiv" with the most recent domain, loaded once when shown.
struct ClientLastActivityRow: View {
    let client: NetworkClient
    let model: ClientsModel

    private enum State: Equatable {
        case loading
        case found(QueryLogEntry)
        case none
        case failed(APIError)
    }

    @SwiftUI.State private var state: State = .loading

    var body: some View {
        LabeledContent("Zuletzt aktiv") {
            switch state {
            case .loading:
                ProgressView()
            case let .found(entry):
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(entry.date, format: .relative(presentation: .named))
                    Text(entry.domain)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            case .none:
                Text("Nicht im Query-Log")
            case let .failed(error):
                Text(error.title).foregroundStyle(AppColor.warning)
            }
        }
        .task(id: client.id) { await load() }
    }

    private func load() async {
        guard !client.ipAddresses.isEmpty else {
            state = .none
            return
        }
        do {
            state = try await model.lastActivity(of: client).map(State.found) ?? .none
        } catch {
            if error != .cancelled { state = .failed(error) }
        }
    }
}
