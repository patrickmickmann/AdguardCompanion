import SwiftUI

/// Loading or failed first load of a screen, with a retry action.
struct LoadStateView: View {
    let error: APIError?
    let retry: () async -> Void

    var body: some View {
        Group {
            if let error {
                ContentUnavailableView {
                    Label(error.title, systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    Button("Erneut versuchen") { Task { await retry() } }
                        .buttonStyle(.glassProminent)
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

extension View {
    /// Shows a write error as an alert and clears it on dismissal.
    func apiErrorAlert(_ error: Binding<APIError?>) -> some View {
        alert(error.wrappedValue?.title ?? "",
              isPresented: Binding { error.wrappedValue != nil } set: { if !$0 { error.wrappedValue = nil } },
              presenting: error.wrappedValue) { _ in
            Button("OK") { error.wrappedValue = nil }
        } message: { value in
            Text(value.message)
        }
    }
}
