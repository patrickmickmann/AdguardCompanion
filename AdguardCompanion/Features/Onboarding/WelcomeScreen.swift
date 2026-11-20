import SwiftUI

/// First-launch screen introducing the app (mockup: "Los geht's").
struct WelcomeScreen: View {
    let onStart: () -> Void
    let onDemo: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xxl) {
                header
                features
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xxl)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) { actions }
        .background(AppColor.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: Spacing.m) {
            BrandMark()
                .padding(.bottom, Spacing.s)
            Text("AdGuard Companion")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Your Network. Your Rules.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            FeatureRow(systemImage: "gauge.with.dots.needle.33percent", text: "DNS-Schutz überwachen")
            FeatureRow(systemImage: "chart.xyaxis.line", text: "Anfragen und Blockierungen analysieren")
            FeatureRow(systemImage: "checkmark.shield", text: "Filter und Regeln verwalten")
            FeatureRow(systemImage: "laptopcomputer.and.iphone", text: "Deine Geräte im Blick behalten")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        VStack(spacing: Spacing.s) {
            Button("Los geht’s", action: onStart)
                .buttonStyle(.primary)
            Button("Demo mit Beispieldaten ansehen", action: onDemo)
                .font(.subheadline)
                .padding(.vertical, Spacing.s)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.s)
        .background(AppColor.background)
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let text: LocalizedStringKey

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(AppColor.protection)
                .frame(width: Metrics.featureIconWidth)
        }
        .font(.body)
    }
}

#Preview {
    WelcomeScreen(onStart: {}, onDemo: {})
}
