import Foundation

/// User-facing texts that differ between query log and statistics.
struct LogKindTexts {
    let kind: LogKind

    var title: String { kind == .queryLog ? "Query-Log" : "Statistik" }
    var enabledTitle: String { kind == .queryLog ? "Anfragen protokollieren" : "Statistik erfassen" }
    var footer: String {
        kind == .queryLog
            ? "Das Query-Log zeigt jede Anfrage mit Gerät und Ergebnis. Anonymisierte IP-Adressen lassen sich keinem Gerät mehr zuordnen."
            : "Die Statistik bildet die Grundlage für die Übersicht und die Top-Listen."
    }
    var clearTitle: String { kind == .queryLog ? "Query-Log leeren?" : "Statistik zurücksetzen?" }
    var clearAction: String { kind == .queryLog ? "Query-Log leeren" : "Statistik zurücksetzen" }
    var clearMessage: String {
        kind == .queryLog
            ? "Alle protokollierten Anfragen werden auf dem Server gelöscht. Das lässt sich nicht rückgängig machen."
            : "Alle Zähler und Verläufe werden auf dem Server gelöscht. Das lässt sich nicht rückgängig machen."
    }

    static func retention(_ duration: Duration) -> String {
        let hours = Int(duration.components.seconds / 3600)
        if hours < 24 || hours % 24 != 0 {
            return hours == 1 ? String(localized: "1 Stunde") : String(localized: "\(hours) Stunden")
        }
        let days = hours / 24
        return days == 1 ? String(localized: "1 Tag") : String(localized: "\(days) Tage")
    }
}
