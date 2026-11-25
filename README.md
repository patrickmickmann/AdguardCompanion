# AdGuard Companion

Native iOS-App zur Überwachung und Verwaltung einer eigenen
[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome)-Installation –
gebaut mit SwiftUI im Stil der Apple-Systemapps.

> Privates Projekt, nicht mit AdGuard verbunden oder von AdGuard unterstützt.

## Funktionen

**Übersicht**
- Schutzstatus auf einen Blick
- DNS-Anfragen, Blockierquote und Antwortzeit mit Verlaufsdiagramm
- Häufigste Domains, blockierte Domains und aktivste Geräte

**Aktivität**
- Query-Log mit Suche und Filtern (erlaubt, blockiert, Gerät)
- Detailansicht pro Anfrage; Domains direkt sperren oder freigeben

**Clients**
- Konfigurierte und automatisch erkannte Geräte, Dual-Stack-Adressen zusammengefasst
- Geräteeinstellungen, Upstreams und letzte Aktivität

**Schutz**
- Schutz pausieren (mit Dauer) und wieder einschalten
- Safe Browsing, Kindersicherung und Safe Search
- Filterlisten: an- und ausschalten, hinzufügen, entfernen, aktualisieren
- Eigene Regeln mit lesbarer Darstellung
- Gesperrte Dienste nach Kategorien, mit Suche
- DNS-Rewrites anlegen, bearbeiten und entfernen

**Einstellungen**
- DNS: Upstream-, Bootstrap- und Fallback-Server (mit Test vor dem Speichern),
  Upstream-Modus, DNSSEC, IPv6, Cache
- Query-Log und Statistik: Erfassung, Aufbewahrung, Anonymisierung, Leeren
- Verschlüsselung: TLS-Status und Zertifikat (nur Anzeige)

**Demo-Modus** mit klar gekennzeichneten Beispieldaten – ganz ohne Server.

## Datenschutz und Sicherheit

- Direkte Verbindung zum eigenen Server, keine Telemetrie, kein Tracking
- Passwort ausschließlich im iOS-Schlüsselbund
- Keine Protokollierung von Zugangsdaten oder DNS-Anfragen
- Reguläre Zertifikatsprüfung; HTTP nur für Adressen im lokalen Netz
- Jede Änderung wird nach dem Schreiben vom Server zurückgelesen und erst
  dann als erfolgreich angezeigt; kritische Aktionen verlangen eine Bestätigung

## Voraussetzungen

- Xcode mit iOS-27-SDK (Deployment Target iOS 27)
- Ein Apple-Account in Xcode (ein kostenloser reicht für eigene Geräte)
- Ein erreichbarer AdGuard-Home-Server mit Benutzername und Passwort

## Einrichtung

1. Repository klonen.
2. `Config/Local.example.xcconfig` nach `Config/Local.xcconfig` kopieren.
3. In `Config/Local.xcconfig` die eigene Team-ID (`DEVELOPMENT_TEAM`) und ein
   eigenes Bundle-ID-Präfix (`BUNDLE_ID_PREFIX`) eintragen. Die Datei ist von
   Git ausgeschlossen.
4. `AdguardCompanion.xcodeproj` öffnen, das eigene iPhone wählen und starten.
5. In der App Serveradresse (z. B. `http://192.168.1.2`), Benutzername und
   Passwort eingeben.

Beim ersten Start fragt iOS nach Zugriff auf das lokale Netzwerk – dieser ist
nötig, um den Server im Heimnetz zu erreichen.

## Projektstruktur

```
AdguardCompanion/
├── App/            App-Einstieg und Verbindungszustand
├── Core/           Netzwerk-Client, Endpunkte, DTOs
├── Data/           Repository (live und Demo), Keychain, Verbindungsspeicher
├── Domain/         Domänenmodelle, Mapping, Validierung
├── DesignSystem/   Farben, Typografie, Abstände, wiederverwendbare Komponenten
└── Features/       Bildschirme und ViewModels je Bereich
AdguardCompanionTests/   Unit-Tests (Swift Testing)
Config/                  Info.plist und Signing-Konfiguration
```

## Tests

```bash
xcodebuild test -project AdguardCompanion.xcodeproj -scheme AdguardCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:AdguardCompanionTests -parallel-testing-enabled NO
```

Die Unit-Tests laufen vollständig ohne Server.
