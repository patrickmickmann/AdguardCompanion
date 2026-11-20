import SwiftUI

/// All addresses AdGuard Home listens on for DNS, grouped by IP version.
struct DNSAddressesScreen: View {
    let addresses: [String]

    private var ipv4: [String] { addresses.filter { !$0.contains(":") } }
    private var ipv6: [String] { addresses.filter { $0.contains(":") } }

    var body: some View {
        List {
            section("IPv4", entries: ipv4)
            section("IPv6", entries: ipv6)
        }
        .navigationTitle("DNS-Adressen")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ title: LocalizedStringKey, entries: [String]) -> some View {
        if !entries.isEmpty {
            Section(title) {
                ForEach(entries, id: \.self) { address in
                    Text(address)
                        .font(AppFont.technical)
                        .textSelection(.enabled)
                }
            }
        }
    }
}
