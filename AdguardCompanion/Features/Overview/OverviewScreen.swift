import SwiftUI

/// Dashboard: protection status, traffic, insights and top lists.
/// Refreshes automatically while visible and on pull-to-refresh.
struct OverviewScreen: View {
    @State private var model: OverviewModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: OverviewModel(repository: repository))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
            .navigationTitle("Übersicht")
            .task { await model.runAutoRefresh() }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = model.snapshot {
            ScrollView {
                OverviewDashboard(snapshot: snapshot, isReachable: model.error == nil, isDemo: model.isDemo)
                    .padding(.horizontal, Spacing.l)
                    .padding(.bottom, Spacing.xl)
                    .frame(maxWidth: Metrics.readableWidth)
                    .frame(maxWidth: .infinity)
            }
            .refreshable { await model.refresh() }
        } else if let error = model.error {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.refresh() } }
                    .buttonStyle(.glassProminent)
            }
        } else {
            ProgressView("Verbinde mit AdGuard Home …")
        }
    }
}

private struct OverviewDashboard: View {
    let snapshot: OverviewModel.Snapshot
    let isReachable: Bool
    let isDemo: Bool

    var body: some View {
        VStack(spacing: Spacing.l) {
            ProtectionHeader(
                summary: ProtectionSummary(status: snapshot.status, isReachable: isReachable),
                version: snapshot.status.version,
                isDemo: isDemo
            )
            TrafficCard(statistics: snapshot.statistics)
            InsightCards(statistics: snapshot.statistics)
            TopListsCard(statistics: snapshot.statistics)
            Text("Aktualisiert um \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
