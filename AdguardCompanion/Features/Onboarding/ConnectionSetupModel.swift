import Foundation
import Observation

/// Validates the entered connection, verifies it against the server and only
/// then stores it. Success is never reported without a confirmed response.
@Observable
final class ConnectionSetupModel {
    var address = ""
    var username = ""
    var password = ""

    private(set) var isVerifying = false
    private(set) var failure: Failure?

    struct Failure: Equatable {
        let title: String
        let message: String
    }

    private let appModel: AppModel

    init(appModel: AppModel) {
        self.appModel = appModel
    }

    var canSubmit: Bool {
        !isVerifying && !address.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.isEmpty && !password.isEmpty
    }

    /// `true` when the entered address would send credentials unencrypted.
    var isInsecureAddress: Bool {
        guard let url = try? ServerAddress.parse(address) else { return false }
        return ServerAddress.isInsecure(url)
    }

    func submit() async {
        guard canSubmit else { return }
        failure = nil

        let baseURL: URL
        do {
            baseURL = try ServerAddress.parse(address)
        } catch {
            failure = Failure(title: "Ungültige Adresse", message: Self.message(for: error))
            return
        }

        let configuration = ServerConfiguration(baseURL: baseURL, username: username)
        isVerifying = true
        defer { isVerifying = false }

        do {
            _ = try await appModel.makeRepository(for: configuration, password: password).fetchServerStatus()
        } catch {
            guard error != .cancelled else { return }
            let message = Self.failureMessage(for: error, schemeWasImplicit: !ServerAddress.hasExplicitScheme(address))
            failure = Failure(title: error.title, message: message)
            return
        }

        do {
            try appModel.completeConnection(configuration, password: password)
        } catch {
            failure = Failure(
                title: "Speichern fehlgeschlagen",
                message: "Die Zugangsdaten konnten nicht im Schlüsselbund gesichert werden."
            )
        }
    }

    /// Adds a hint when HTTPS was assumed and the connection failed in a way
    /// that is typical for servers only offering HTTP. Never downgrades silently.
    static func failureMessage(for error: APIError, schemeWasImplicit: Bool) -> String {
        let suggestsMissingHTTP: Bool = switch error {
        case .secureConnectionFailed, .serverUnreachable, .timeout, .transport: true
        default: false
        }
        guard schemeWasImplicit, suggestsMissingHTTP else { return error.message }
        return error.message
            + " Ohne Angabe wird HTTPS verwendet. Nutzt dein Server nur HTTP, gib die Adresse mit http:// ein."
    }

    private static func message(for error: ServerAddressError) -> String {
        switch error {
        case .empty: "Bitte gib die Adresse deines AdGuard-Home-Servers ein."
        case .invalid: "Beispiel: https://adguard.home:3000"
        case .unsupportedScheme: "Nur http:// und https:// werden unterstützt."
        }
    }
}
