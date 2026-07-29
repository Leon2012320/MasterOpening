# CLAUDE.md

Arbeitsanweisungen für dieses Repository.

## Kommandos

```bash
cd app && flutter analyze                                    # muss sauber sein
cd app && flutter test
cd app && dart run build_runner build
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
  referenzieren Repertoire-Knoten über den SHA-1 aus Startstellung und
  UCI-Zugfolge ab Wurzel, nie über eine Drift-Row-ID.
- **Der Variantenbaum lebt als PGN.** `Repertoires.pgn` ist die Quelle der
  Wahrheit; `RepertoireRepository.treeOf` parst ihn einmal je Revision in
  einen unveränderlichen `RepertoireTree`. Es gibt bewusst keine Tabelle mit
  einer Zeile je Zug: PGN ist ohnehin das Austauschformat, ein Repertoire ist
  klein genug zum Einlesen am Stück, und der Abgleich überträgt ein Dokument
  statt tausender Zeilen. Nur der Lernstand ist normalisiert — je `pathHash`
  eine Zeile in `NodeProgress`.
- **Fortschritt nur für eigene Züge.** Die Antworten des Gegners gibt die App
  vor; `NodeProgress` bekommt ausschliesslich Knoten der Repertoire-Farbe.
- **Schachlogik nur in `lib/chess/`.** Features rufen `dartchess` nicht direkt
  auf, sondern gehen über diese Kapselung. Gespeichert wird immer englisches
  Standard-SAN; `SanNotation.localize` übersetzt erst für die Anzeige.
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
`letter-spacing -0.015em`. Drei Erscheinungsbilder: Hell, Dunkel, System.

## Was nicht getan werden soll

- Keine Abhängigkeit hinzufügen, ohne vorher `flutter pub add` die Auflösung
  bestätigen zu lassen — die Kette `drift_dev` ↔ `analyzer` ist eng.
- Keine generierten Dateien (`*.g.dart`, `*.drift.dart`, `lib/l10n/generated/`)
  von Hand bearbeiten oder committen.
- Keine Secrets ins Repo (siehe `.gitignore`).
