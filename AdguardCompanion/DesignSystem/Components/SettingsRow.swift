import SwiftUI

/// Settings-app style row: icon tile, title, trailing value.
struct SettingsRow<Value: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color
    private let value: Value

    init(_ title: LocalizedStringKey, systemImage: String, color: Color, @ViewBuilder value: () -> Value) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.value = value()
    }

    var body: some View {
        LabeledContent {
            value.foregroundStyle(.secondary)
        } label: {
            Label { Text(title).foregroundStyle(Color.primary) } icon: { IconTile(systemImage: systemImage, color: color) }
        }
    }
}
