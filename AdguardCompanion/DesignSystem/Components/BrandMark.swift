import SwiftUI

/// The AdGuard Companion shield mark built from SF Symbols.
struct BrandMark: View {
    var size: CGFloat = Metrics.brandMarkLarge

    var body: some View {
        Image(systemName: "checkmark.shield.fill")
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, AppColor.protection.gradient)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
