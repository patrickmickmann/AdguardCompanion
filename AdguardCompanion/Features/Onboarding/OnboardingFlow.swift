import SwiftUI

/// Welcome screen followed by the connection setup.
struct OnboardingFlow: View {
    @Environment(AppModel.self) private var appModel
    @State private var showsSetup = false
    @State private var demoError: ConnectionStoreError?

    var body: some View {
        NavigationStack {
            WelcomeScreen(
                onStart: { showsSetup = true },
                onDemo: startDemo
            )
            .navigationDestination(isPresented: $showsSetup) {
                ConnectionSetupScreen(model: ConnectionSetupModel(appModel: appModel))
            }
        }
        .alert("Hinweis", isPresented: .constant(appModel.restoreProblem != nil && !showsSetup)) {
            Button("Verbinden") { showsSetup = true }
        } message: {
            Text(appModel.restoreProblem ?? "")
        }
        .alert(
            "Demo-Modus konnte nicht gestartet werden",
            isPresented: Binding(get: { demoError != nil }, set: { if !$0 { demoError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    private func startDemo() {
        do {
            try appModel.startDemo()
        } catch {
            demoError = error
        }
    }
}
