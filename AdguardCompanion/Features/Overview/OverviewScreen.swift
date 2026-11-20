import SwiftUI

/// Dashboard: server status, key metrics, traffic trend and top lists.
struct OverviewScreen: View {
    @State private var model: OverviewModel

    init(repository: any AdGuardRepository) {
        _model = State(initialValue: OverviewModel(repository: repository))
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
            .navigationTitle("Overview")
            .toolbar { refreshButton }
            .task { await model.runAutoRefresh() }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = model.snapshot {
            ScrollView {
                OverviewDashboard(snapshot: snapshot, error: model.error, isDemo: model.isDemo)
                    .padding(.horizontal, Spacing.l)
                    .padding(.bottom, Spacing.xl)
            }
            .refreshable { await model.refresh() }
        } else if let error = model.error {
            ContentUnavailableView {
                Label(error.title, systemImage: "wifi.exclamationmark")
            } description: {
                Text(error.message)
            } actions: {
                Button("Erneut versuchen") { Task { await model.refresh() } }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ProgressView("Verbinde mit AdGuard Home …")
        }
    }

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await model.refresh() }
            } label: {
                Label("Aktualisieren", systemImage: "arrow.clockwise")
            }
            .disabled(model.isRefreshing)
            .symbolEffect(.rotate, isActive: model.isRefreshing)
        }
    }
}

/// Scrollable dashboard content for a loaded snapshot.
private struct OverviewDashboard: View {
    let snapshot: OverviewModel.Snapshot
    let error: APIError?
    let isDemo: Bool

    private var statistics: DashboardStatistics { snapshot.statistics }

    var body: some View {
        VStack(spacing: Spacing.m) {
            if isDemo { DemoNotice() }
            ServerStatusCard(status: snapshot.status, isReachable: error == nil, isDemo: isDemo)
            if let error { StaleDataNotice(error: error, fetchedAt: snapshot.fetchedAt) }
            MetricsSection(statistics: statistics)
            TrafficChartCard(statistics: statistics)
            RankedListCard(title: "Häufigste Domains", entries: statistics.topQueriedDomains,
                           tone: .positive, style: .domain)
            RankedListCard(title: "Häufig blockiert", entries: statistics.topBlockedDomains,
                           tone: .critical, style: .domain)
            RankedListCard(title: "Aktivste Clients", entries: statistics.topClients,
                           tone: .neutral, style: .client)
            FreshnessFooter(fetchedAt: snapshot.fetchedAt)
        }
    }
}
