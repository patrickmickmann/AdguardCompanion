import Foundation

extension APIError {
    /// Short, user-facing headline. Never contains credentials.
    var title: String {
        switch self {
        case .offline: "Keine Internetverbindung"
        case .timeout: "Zeitüberschreitung"
        case .serverUnreachable: "Server nicht erreichbar"
        case .secureConnectionFailed: "Sichere Verbindung fehlgeschlagen"
        case .unauthorized: "Anmeldung abgelehnt"
        case .http: "Serverfehler"
        case .invalidResponse, .decodingFailed: "Unerwartete Antwort"
        case .cancelled: "Abgebrochen"
        case .transport: "Verbindungsfehler"
        }
    }

    /// Explanation with a concrete next step.
    var message: String {
        switch self {
        case .offline:
            "Das iPhone ist nicht mit einem Netzwerk verbunden."
        case .timeout:
            "AdGuard Home hat nicht rechtzeitig geantwortet. Prüfe, ob der Server läuft."
        case .serverUnreachable:
            "Prüfe die Serveradresse und ob sich das iPhone im selben Netzwerk befindet."
        case .secureConnectionFailed:
            "Das TLS-Zertifikat des Servers konnte nicht überprüft werden."
        case .unauthorized:
            "Benutzername oder Passwort sind nicht korrekt."
        case let .http(statusCode, message):
            message.map { "HTTP \(statusCode): \($0)" } ?? "Der Server antwortete mit HTTP \(statusCode)."
        case .invalidResponse, .decodingFailed:
            "Die Antwort entspricht nicht dem erwarteten AdGuard-Home-Format. Ist die Adresse korrekt?"
        case .cancelled:
            "Die Anfrage wurde abgebrochen."
        case let .transport(code):
            "Die Anfrage ist fehlgeschlagen (Code \(code))."
        }
    }
}
