import SwiftUI

/// Switches between onboarding and the main tab interface.
struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if let connection = appModel.connection {
                MainTabView(connection: connection)
            } else {
                OnboardingFlow()
            }
        }
        .animation(.smooth, value: appModel.connection == nil)
    }
}
