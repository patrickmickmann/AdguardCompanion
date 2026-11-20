import SwiftUI

/// Standard rounded surface used for grouped dashboard content.
struct SurfaceCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = Spacing.l, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface, in: .rect(cornerRadius: Radius.large))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.large)
                    .strokeBorder(AppColor.outline, lineWidth: Metrics.outlineWidth)
            }
    }
}

/// Title row used at the top of a card.
struct CardHeader: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(AppFont.cardTitle)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
