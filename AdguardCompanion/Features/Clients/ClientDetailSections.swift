import SwiftUI

/// Protection switches. Shows "Global" instead of individual values when the
/// client inherits the server-wide settings, because those values do not apply.
struct ClientProtectionSection: View {
    let settings: ClientSettings

    var body: some View {
        Section {
            if settings.usesGlobalSettings {
                SettingsRow("Schutzeinstellungen", systemImage: "globe", color: .gray) {
                    Text("Global")
                }
            } else {
                row("DNS-Filterung", "line.3.horizontal.decrease", AppColor.protection, settings.filteringEnabled)
                row("Safe Browsing", "exclamationmark.shield.fill", AppColor.warning, settings.safeBrowsingEnabled)
                row("Kindersicherung", "figure.and.child.holdinghands", Color(uiColor: .systemPurple),
                    settings.parentalControlEnabled)
                row("Safe Search", "magnifyingglass", AppColor.network, settings.safeSearchEnabled)
            }
        } header: {
            Text("Schutz")
        } footer: {
            Text(settings.usesGlobalSettings
                 ? "Dieser Client übernimmt die globalen Schutzeinstellungen des Servers."
                 : "Dieser Client hat eigene Schutzeinstellungen.")
        }
    }

    private func row(_ title: LocalizedStringKey, _ symbol: String, _ color: Color, _ isOn: Bool) -> some View {
        SettingsRow(title, systemImage: symbol, color: color) {
            Text(isOn ? "Ein" : "Aus")
        }
    }
}

/// Blocked services, upstream servers and logging exclusions.
struct ClientRoutingSection: View {
    let settings: ClientSettings
    let serviceNames: [String: String]

    var body: some View {
        Section("Dienste und Upstreams") {
            SettingsRow("Gesperrte Dienste", systemImage: "nosign", color: AppColor.blocked) {
                Text(blockedServicesText)
            }
            SettingsRow("Upstream-Server", systemImage: "arrow.up.arrow.down", color: AppColor.performance) {
                Text(settings.upstreams.isEmpty ? "Global" : "\(settings.upstreams.count) eigene")
            }
            ForEach(settings.upstreams, id: \.self) { upstream in
                Text(upstream)
                    .font(AppFont.technicalSmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            SettingsRow("Im Query-Log", systemImage: "list.bullet.rectangle", color: .gray) {
                Text(settings.excludedFromQueryLog ? "Ausgeschlossen" : "Erfasst")
            }
            SettingsRow("In der Statistik", systemImage: "chart.bar.fill", color: .gray) {
                Text(settings.excludedFromStatistics ? "Ausgeschlossen" : "Erfasst")
            }
        }
    }

    private var blockedServicesText: String {
        if settings.usesGlobalBlockedServices { return String(localized: "Global") }
        if settings.blockedServiceIDs.isEmpty { return String(localized: "Keine") }
        return settings.blockedServiceIDs
            .map { serviceNames[$0] ?? $0 }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .formatted(.list(type: .and))
    }
}

/// Where AdGuard Home learned about an automatically discovered client.
struct ClientDiscoverySection: View {
    let source: DiscoverySource
    let whois: [String: String]

    var body: some View {
        Section {
            SettingsRow("Erkannt über", systemImage: "dot.radiowaves.left.and.right", color: .gray) {
                Text(sourceText)
            }
            ForEach(whois.sorted { $0.key < $1.key }, id: \.key) { key, value in
                LabeledContent(key.capitalized, value: value)
            }
        } header: {
            Text("Herkunft")
        } footer: {
            Text("Für automatisch erkannte Geräte gelten die globalen Schutzeinstellungen.")
        }
    }

    private var sourceText: String {
        switch source {
        case .whois: "WHOIS"
        case .arp: "ARP"
        case .reverseDNS: "Reverse DNS"
        case .dhcp: "DHCP"
        case .hostsFile: "Hosts-Datei"
        case let .other(raw): raw.isEmpty ? String(localized: "Unbekannt") : raw
        }
    }
}
