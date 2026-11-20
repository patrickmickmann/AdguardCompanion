import SwiftUI

/// Rounded card on the grouped background, as used in Health and Fitness.
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
            .background(AppColor.surface, in: .rect(cornerRadius: Radius.card, style: .continuous))
    }
}

/// Card header in Health style: tinted symbol and label, optional trailing detail.
struct CardHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color
    private let trailing: Trailing

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        tint: Color,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label(title, systemImage: systemImage)
                .font(AppFont.cardLabel)
                .foregroundStyle(tint)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            trailing
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

/// Large rounded value with a smaller unit, e.g. "265.910 Anfragen".
struct ValueWithUnit: View {
    let value: String
    let unit: LocalizedStringKey
    var font: Font = AppFont.heroValue

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text(value)
                .font(font)
                .contentTransition(.numericText())
            Text(unit)
                .font(AppFont.unit)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}
