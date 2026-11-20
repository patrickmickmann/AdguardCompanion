import SwiftUI

/// The global protection switch: current state and the matching action.
struct ProtectionStatusSection: View {
    let settings: ProtectionSettings
    let model: ProtectionModel

    @ScaledMetric(relativeTo: .title) private var symbolSize: CGFloat = 40

    private var summary: ProtectionSummary { ProtectionSummary(filtering: settings.protection) }

    var body: some View {
        Section {
            HStack(spacing: Spacing.m) {
                Image(systemName: summary.systemImage)
                    .font(.system(size: symbolSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, summary.tone.color.gradient)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: symbolSize * 1.1)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(summary.title).font(.headline)
                    Text(summary.detail).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.xs)
            .accessibilityElement(children: .combine)
            .animation(.smooth, value: summary)

            actionButton
                .disabled(model.isWorking)
        } footer: {
            Text("Der Schutz umfasst Filterlisten, eigene Regeln, gesperrte Dienste und die Schutzfunktionen. Der DNS-Server beantwortet Anfragen auch ohne Schutz weiter.")
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isApplyingProtection {
            HStack {
                Text("Wird übernommen …").foregroundStyle(.secondary)
                Spacer()
                ProgressView()
            }
        } else if settings.protection == .enabled {
            Button {
                model.isChoosingPause = true
            } label: {
                Label("Schutz pausieren …", systemImage: "pause.circle.fill")
                    .foregroundStyle(AppColor.warning)
            }
        } else {
            Button {
                Task { await model.apply(.enableProtection) }
            } label: {
                Label("Schutz einschalten", systemImage: "play.circle.fill")
                    .foregroundStyle(AppColor.protection)
            }
        }
    }

    private var isApplyingProtection: Bool {
        switch model.pendingChange {
        case .enableProtection?, .pauseProtection?, .disableProtection?: true
        default: false
        }
    }
}

/// Safe Browsing, parental control and Safe Search switches.
struct ProtectionFeaturesSection: View {
    let isProtectionOn: Bool
    let model: ProtectionModel

    var body: some View {
        Section {
            ForEach(ProtectionFeature.allCases) { feature in
                Toggle(isOn: binding(for: feature)) {
                    HStack(spacing: Spacing.m) {
                        IconTile(systemImage: feature.systemImage, color: feature.color)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(feature.title)
                            Text(feature.detail).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(model.isWorking)
            }
        } header: {
            Text("Schutzfunktionen")
        } footer: {
            if !isProtectionOn {
                Text("Diese Funktionen wirken nur, solange der Schutz eingeschaltet ist.")
            }
        }
    }

    private func binding(for feature: ProtectionFeature) -> Binding<Bool> {
        Binding {
            model.isOn(feature)
        } set: { isOn in
            Task { await model.apply(feature.change(to: isOn)) }
        }
    }
}
