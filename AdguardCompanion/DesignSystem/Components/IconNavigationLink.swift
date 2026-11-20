import SwiftUI

/// Settings-app style navigation row with a colored icon tile.
struct IconNavigationLink<Destination: View>: View {
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    init(_ title: LocalizedStringKey, systemImage: String, color: Color,
         @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            Label {
                Text(title)
            } icon: {
                IconTile(systemImage: systemImage, color: color)
            }
        }
    }
}
