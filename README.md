# MasterOpening

Ein Schach-Eröffnungstrainer für Android: eigenes Repertoire aufbauen, mit Spaced
Repetition trainieren, echte Partien von Lichess analysieren und die Lücken
schließen, die im eigenen Repertoire fehlen.

**Projektseite:** <https://leon2012320.github.io/MasterOpening/>

## Aufbau

```
app/        Flutter-App (Dart)         → das Produkt
backend/    Fastify + Prisma (Node/TS) → Konten und Cloud-Sync
tools/      Node-Skripte               → generiert die Eröffnungsbibliothek
docs/       Projektseite               → wird als GitHub Pages veröffentlicht
```

## Keine Web-Version

Die App läuft nicht im Browser. `dartchess` rechnet mit 64-Bit-Bitboards, die
JavaScript nicht exakt darstellen kann, und deklariert deshalb ausdrücklich kein
Web als Zielplattform. Flutter erzeugt bei `build web` immer auch ein
JavaScript-Fallback, `--wasm` allein hilft also nicht. `docs/` enthält
stattdessen eine Projektseite; die App selbst erscheint im Play Store.

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

## Lichess-Anbindung

Die Anmeldung läuft über OAuth 2.0 mit PKCE (S256) — ohne Client-Geheimnis, weil
eine mobile App keines bewahren kann. Die Rückleitung geht an
`masteropening://oauth/lichess`; das passende Intent-Filter steht im
`AndroidManifest.xml`. Angefordert werden nur `preference:read` und `study:read`:
lesender Zugriff, kein Spielen, keine Änderung am Konto.

Das Zugriffstoken liegt im Keystore beziehungsweise Keychain
(`flutter_secure_storage`), das Profil als JSON in der Datenbank — damit der Tab
auch ohne Netz etwas anzeigt. Partien kommen als NDJSON-Strom herein und werden
laufend verbucht; der Import merkt sich den Zeitpunkt der jüngsten Partie und
holt beim nächsten Mal nur das, was seitdem dazugekommen ist. Er ist idempotent,
eine doppelt gelieferte Partie bleibt eine Zeile.

## Engine

Stockfish liegt als native Bibliothek bei und läuft nur auf Android und iOS —
für Windows und Linux bringt das Paket keine mit. Statt dort abzustürzen
liefert die App eine Engine, die es nicht gibt: `NoopEngineService` antwortet
auf jede Frage mit „keine Angabe". Jede Stelle, die eine Bewertung anzeigt,
muss ohnehin damit umgehen können.

Das UCI-Protokoll selbst spricht `UciEngineService` über einen austauschbaren
Transport. Dadurch lässt sich prüfen, ob die App richtig mit einer Engine
redet, ohne eine native Bibliothek zu starten.

## Cloud-Sync

Der Abgleich ist optional und standardmäßig aus. Die Serveradresse steht beim
Bauen fest:

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.org
```

Ohne diesen Wert bietet die App keinen Abgleich an — ein Knopf, der nur
scheitern kann, wäre schlimmer als keiner. Details zum Protokoll stehen in
[`backend/README.md`](backend/README.md).

## Lizenzhinweise

Die Eröffnungsbibliothek wird aus der frei lizenzierten Lichess-Masters-Datenbank
und den ECO-Namen aus [`lichess-org/chess-openings`](https://github.com/lichess-org/chess-openings)
erzeugt; die Beschreibungen und Pläne sind eigene Texte. Die Schrift
[Inter](https://github.com/rsms/inter) steht unter der SIL Open Font License
(siehe `app/assets/fonts/Inter-OFL.txt`).
