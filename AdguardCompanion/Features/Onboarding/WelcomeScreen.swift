import SwiftUI

/// First-launch screen in the style of Apple's welcome sheets.
struct WelcomeScreen: View {
    let onStart: () -> Void
    let onDemo: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xxl + Spacing.s) {
                header
                features
            }
            .padding(.horizontal, Spacing.xl + Spacing.s)
            .padding(.top, Spacing.xxl * 2)
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: Metrics.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) { actions }
        .background(AppColor.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: Spacing.l) {
            BrandMark()
            Text("Willkommen bei\nAdGuard Companion")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            WelcomeFeature(systemImage: "checkmark.shield.fill", color: AppColor.protection,
                           title: "Schutz auf einen Blick",
                           detail: "Sieh sofort, ob die DNS-Filterung in deinem Netzwerk aktiv ist.")
            WelcomeFeature(systemImage: "chart.bar.fill", color: AppColor.network,
                           title: "Anfragen verstehen",
                           detail: "Verfolge, welche Domains angefragt und welche blockiert werden.")
            WelcomeFeature(systemImage: "laptopcomputer.and.iphone", color: AppColor.warning,
                           title: "Geräte im Netzwerk",
                           detail: "Erkenne, welche Geräte den meisten DNS-Verkehr erzeugen.")
            WelcomeFeature(systemImage: "lock.fill", color: Color(uiColor: .systemIndigo),
                           title: "Privat aus Prinzip",
                           detail: "Direkte Verbindung zu deinem Server. Kein Tracking, keine Analyse, Zugangsdaten im Schlüsselbund.")
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.m) {
            Button(action: onStart) {
                Text("Server verbinden")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)

            Button("Mit Beispieldaten ausprobieren", action: onDemo)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, Spacing.xl + Spacing.s)
        .padding(.top, Spacing.m)
        .padding(.bottom, Spacing.s)
        .frame(maxWidth: Metrics.readableWidth)
        .frame(maxWidth: .infinity)
        .background(AppColor.background)
    }
}

private struct WelcomeFeature: View {
    let systemImage: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    @ScaledMetric(relativeTo: .title) private var iconWidth: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.l) {
            Image(systemName: systemImage)
                .font(.title)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeScreen(onStart: {}, onDemo: {})
}
