import SwiftUI

/// Connection, DNS server and DNS filtering status at a glance.
struct ServerStatusCard: View {
    let status: ServerStatus
    let isReachable: Bool
    let isDemo: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Version sits beside the title, or below it at accessibility text sizes.
    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                headerLayout {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(isDemo ? "AdGuard Home (Demo)" : "AdGuard Home")
                            .font(AppFont.cardTitle)
                        StatusLabel(text: serverText, tone: serverTone)
                    }
                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.s) }
                    if let version = status.version {
                        Text(version)
                            .font(AppFont.technicalSmall)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Version \(version)")
                    }
                }
                Divider()
                Label {
                    Text(filteringText)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: filteringSymbol)
                        .foregroundStyle(filteringTone.color)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var serverText: String {
        if !isReachable { return "Nicht erreichbar" }
        return status.isDNSRunning ? "Läuft" : "DNS-Server gestoppt"
    }

    private var serverTone: StatusTone {
        guard isReachable else { return .critical }
        return status.isDNSRunning ? .positive : .critical
    }

    private var filteringText: String {
        switch status.filtering {
        case .enabled:
            "DNS-Filterung aktiv"
        case .disabled:
            "DNS-Filterung deaktiviert"
        case let .paused(until):
            "DNS-Filterung pausiert bis \(until.formatted(date: .omitted, time: .shortened))"
        }
    }

    private var filteringTone: StatusTone {
        status.filtering == .enabled ? .positive : .warning
    }

    private var filteringSymbol: String {
        status.filtering == .enabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill"
    }
}
