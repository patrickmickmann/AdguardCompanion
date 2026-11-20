import SwiftUI

/// Settings-style row: device symbol, name, address and request count.
struct ClientRow: View {
    let client: NetworkClient

    var body: some View {
        HStack(spacing: Spacing.m) {
            IconTile(systemImage: client.symbol, color: client.isConfigured ? AppColor.network : .gray)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(client.displayTitle)
                    .foregroundStyle(client.hasName ? .primary : .secondary)
                    .lineLimit(1)
                if let identifier = client.secondaryIdentifier {
                    Text(identifier)
                        .font(AppFont.technicalSmall)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: Spacing.s)
            if let count = client.requestCount {
                Text(count.formatted(.number.notation(.compactName)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(client.requestCount.map { "\($0.formatted()) Anfragen" } ?? "")
    }
}

extension NetworkClient {
    /// The identifier shown under the name, unless it equals the name.
    var secondaryIdentifier: String? {
        let shown = searchableAddress ?? identifiers.first
        return hasName && shown == name ? nil : shown
    }

    /// A best-effort device symbol derived from AdGuard tags or the name.
    var symbol: String {
        let tokens = ([name] + tags).joined(separator: " ").lowercased()
            .split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let mapping: [(keys: [String], symbol: String)] = [
            (["iphone", "phone", "android", "pixel", "galaxy"], "iphone"),
            (["ipad", "tablet"], "ipad"),
            (["macbook", "laptop", "notebook"], "laptopcomputer"),
            (["mac", "imac", "desktop", "pc"], "desktopcomputer"),
            (["tv", "chromecast", "roku"], "appletv"),
            (["sonos", "speaker", "homepod", "echo"], "hifispeaker"),
            (["printer", "drucker"], "printer"),
            (["plug", "steckdose", "bulb", "lamp", "light", "meross", "shelly", "hue"], "lightbulb"),
            (["nas", "server", "pi", "raspberry", "docker"], "server.rack"),
            (["router", "fritz", "switch"], "wifi.router"),
        ]
        // Short keys must match a whole word ("tv"), longer ones a word prefix ("sonoszp").
        func matches(_ key: String) -> Bool {
            tokens.contains { key.count <= 3 ? $0 == key : $0.hasPrefix(key) }
        }
        return mapping.first { $0.keys.contains(where: matches) }?.symbol ?? "network"
    }

    private var tags: [String] {
        if case let .configured(settings) = kind { return settings.tags }
        return []
    }
}
