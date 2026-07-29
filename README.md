# MasterOpening

Ein Schach-Eröffnungstrainer für Android: eigenes Repertoire aufbauen, mit Spaced
Repetition trainieren, echte Partien von Lichess analysieren und die Lücken
schließen, die im eigenen Repertoire fehlen.

## Aufbau

```
app/        Flutter-App (Dart)         → das Produkt
backend/    Fastify + Prisma (Node/TS) → Konten und Cloud-Sync
tools/      Node-Skripte               → generiert die Eröffnungsbibliothek
```

## Voraussetzungen

| Werkzeug | Version |
| --- | --- |
| Flutter | 3.44+ (Dart 3.12+) |
| Node.js | 22+ |
| JDK | 17 oder 21 |
| Android SDK | Platform-Tools + API 35 |

## App starten

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

`flutter run -d windows` ist für schnelle UI-Iteration gedacht, der Realtest
läuft auf einem Android-Gerät oder -Emulator.

## Qualität prüfen

```bash
cd app && flutter analyze && flutter test
```

## Architektur in Kürze

Die App ist **offline-first**: die lokale Drift-Datenbank ist die Quelle der
Wahrheit, das Konto ist eine Sync-Schicht darüber. Jede synchronisierbare Zeile
trägt `updatedAt`, `deletedAt` (Soft-Delete) und `revision`.

Jeder Knoten im Repertoire-Baum hat einen `pathHash` — den SHA-1 der UCI-Zugfolge
ab der Wurzel. Dadurch bleibt der Lernfortschritt an der Zugfolge hängen und
nicht an einer Datenbank-ID: der Baum kann bearbeitet werden, ohne dass
Statistiken verloren gehen, und Sync kommt ohne Konfliktauflösung pro Knoten aus.

Ordnerstruktur der App: `lib/core/` enthält Theme, Router, Datenbank, Netzwerk
und die geteilten Widgets; `lib/chess/` kapselt Schachlogik und PGN;
`lib/features/<feature>/` enthält je Feature `data/`, `domain/` und
`presentation/`.

## Lizenzhinweise

Die Eröffnungsbibliothek wird aus der frei lizenzierten Lichess-Masters-Datenbank
und den ECO-Namen aus [`lichess-org/chess-openings`](https://github.com/lichess-org/chess-openings)
erzeugt; die Beschreibungen und Pläne sind eigene Texte. Die Schrift
[Inter](https://github.com/rsms/inter) steht unter der SIL Open Font License
(siehe `app/assets/fonts/Inter-OFL.txt`).
