import SwiftUI

/// Full-width filled button for the single primary action of a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColor.onProtection)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .background(AppColor.protection, in: .rect(cornerRadius: Radius.button))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
