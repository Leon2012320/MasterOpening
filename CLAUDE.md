# CLAUDE.md

Arbeitsanweisungen für dieses Repository.

## Kommandos

```bash
cd app && flutter analyze                                    # muss sauber sein
cd app && flutter test
cd app && dart run build_runner build --delete-conflicting-outputs
cd backend && npm test
```

## Sprache

UI-Texte, Kommentare und Commit-Nachrichten sind deutsch; Bezeichner im Code
sind englisch. Alle Nutzertexte gehören in `app/lib/l10n/app_de.arb` und
`app_en.arb` — niemals als Literal in ein Widget.

## Architektur-Regeln

- **Offline-first.** Die Drift-Datenbank ist die Quelle der Wahrheit. Kein
  Feature darf eine Netzwerkantwort abwarten, um Inhalte anzuzeigen.
- **`pathHash` statt Zeilen-ID.** Lernfortschritt, Statistik und Sync
  referenzieren Repertoire-Knoten über den SHA-1 ihrer UCI-Zugfolge ab Wurzel,
  nie über die Drift-Row-ID.
- **Schachlogik nur in `lib/chess/`.** Features rufen `dartchess` nicht direkt
  auf, sondern gehen über diese Kapselung.
- **Providers werden von Hand geschrieben.** `riverpod_generator` ist bewusst
  nicht installiert (Analyzer-Konflikt mit `drift_dev`); `freezed` ebenfalls
  nicht — stattdessen Dart-3-Sealed-Classes und `equatable`.
- **Design-Tokens statt Farbliteralen.** Farben, Abstände und Radien kommen aus
  `AppTokens` (ThemeExtension in `lib/core/theme/`), nie als `Color(0x…)` im
  Widget.

## Design

Verbindlich ist das Nocturne-System aus dem Entwurf: Akzent als Linie statt
Fläche (Buttons sind outline), Trennlinien laufen an den Enden über 48 px
transparent aus, Radien 4/8/14, Schrift Inter mit Heading-Gewicht 500 und
`letter-spacing -0.015em`. Vier Themes: Hell, Dunkel, Schwarz (AMOLED), System.

## Was nicht getan werden soll

- Keine Abhängigkeit hinzufügen, ohne vorher `flutter pub add` die Auflösung
  bestätigen zu lassen — die Kette `drift_dev` ↔ `analyzer` ist eng.
- Keine generierten Dateien (`*.g.dart`, `*.drift.dart`, `lib/l10n/generated/`)
  von Hand bearbeiten oder committen.
- Keine Secrets ins Repo (siehe `.gitignore`).
