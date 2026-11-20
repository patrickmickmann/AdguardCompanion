import SwiftUI

/// App-icon style mark: white shield on an AdGuard-green rounded square.
struct BrandMark: View {
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 88

    var body: some View {
        Image(systemName: "checkmark.shield.fill")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                AppColor.protection.gradient,
                in: .rect(cornerRadius: size * 0.225, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// Settings-app style icon tile: white symbol on a colored rounded square.
struct IconTile: View {
    let systemImage: String
    let color: Color

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 29

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .rect(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}
