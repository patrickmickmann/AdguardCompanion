# AdGuard Companion

Native iOS-App zur Überwachung und Verwaltung einer eigenen
[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome)-Installation.
Privates Projekt, nicht mit AdGuard verbunden.

## Voraussetzungen

- Xcode mit iOS-27-SDK
- Ein Apple-Developer-Account (ein kostenloser reicht für die Installation auf eigenen Geräten)
- Ein erreichbarer AdGuard-Home-Server mit Benutzername und Passwort

## Einrichtung

1. `Config/Local.example.xcconfig` nach `Config/Local.xcconfig` kopieren.
2. Dort die eigene Team-ID (`DEVELOPMENT_TEAM`) und ein eigenes Bundle-ID-Präfix
   (`BUNDLE_ID_PREFIX`) eintragen. Die Datei ist von Git ausgeschlossen.
3. `AdguardCompanion.xcodeproj` öffnen, das eigene iPhone wählen und starten.
4. In der App Serveradresse, Benutzername und Passwort eingeben. Das Passwort
   wird ausschließlich im iOS-Schlüsselbund gespeichert.

Ohne Server lässt sich die App im Demo-Modus mit klar gekennzeichneten
Beispieldaten ausprobieren.

## Tests

```bash
xcodebuild test -project AdguardCompanion.xcodeproj -scheme AdguardCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:AdguardCompanionTests -parallel-testing-enabled NO
```
