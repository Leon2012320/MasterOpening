# MasterOpening — Backend

Konten und Cloud-Sync. Fastify 5, Prisma, Zod, TypeScript.

Der Dienst ist bewusst klein. Die App ist offline-first: sie funktioniert
vollständig ohne Netz, und dieser Server ist nur der Briefkasten zwischen zwei
Geräten. Er rechnet nichts aus, was die App nicht schon weiß — kein FSRS, keine
Statistik, keine Schachlogik.

## Starten

```bash
cd backend
npm install
cp .env.example .env      # JWT_SECRET ersetzen
npx prisma migrate deploy
npm run dev
```

Der Dienst hört danach auf <http://localhost:3000>; `GET /health` antwortet mit
dem Zustand samt Datenbankprüfung.

## Prüfen

```bash
cd backend && npm run typecheck && npm run lint && npm test
```

Die Tests laufen gegen eine echte SQLite-Datei im Temp-Verzeichnis. Das Schema
wird einmal je Testprozess angelegt und danach nur kopiert; Lichess wird nicht
befragt, die Prüfung des Tokens ist im Test ausgetauscht.

## Endpunkte

| Methode | Pfad | Zweck |
| --- | --- | --- |
| `GET` | `/health` | Lebenszeichen inklusive Datenbank |
| `POST` | `/v1/auth/lichess` | Lichess-Token einlösen, eigenes Tokenpaar erhalten |
| `POST` | `/v1/auth/refresh` | Zugriffstoken erneuern (mit Rotation) |
| `POST` | `/v1/auth/logout` | Alle Erneuerungs-Token entwerten |
| `GET` | `/v1/me` | Eigenes Profil |
| `PATCH` | `/v1/me` | Anzeigename ändern |
| `DELETE` | `/v1/me` | Konto und alle Daten löschen |
| `GET` | `/v1/sync?since=` | Änderungen seit einer Marke abholen |
| `POST` | `/v1/sync` | Eigene Änderungen hochladen |
| `GET`/`POST` | `/v1/devices` | Geräte auflisten und anmelden |
| `DELETE` | `/v1/devices/:id` | Gerät entfernen |

## Wie die Anmeldung funktioniert

Die App meldet sich bei Lichess an (OAuth 2.0 mit PKCE) und schickt das
erhaltene Lichess-Token einmalig an `/v1/auth/lichess`. Der Server fragt damit
selbst `GET /api/account` bei Lichess ab — auf das Wort des Clients hin ein
Konto anzulegen hieße, jedem die Identität jedes anderen zu überlassen. Das
Lichess-Token wird nicht gespeichert; ab da arbeiten beide Seiten mit eigenen
Token.

Zugriffstoken sind kurzlebig (15 Minuten), Erneuerungs-Token leben 60 Tage und
liegen nur als SHA-256-Hash in der Datenbank. Jede Erneuerung gibt ein neues
aus und entwertet das alte. Taucht ein bereits entwertetes wieder auf, wurde es
kopiert — dann fällt die ganze Familie, und beide Geräte müssen sich neu
anmelden.

## Wie der Abgleich funktioniert

Repertoires reisen als PGN-Dokument, der Lernstand als Zeile je `pathHash` —
genau wie lokal. Es gibt keine Tabelle mit einer Zeile je Zug.

`POST /v1/sync` schickt Änderungen hoch und bekommt zurück, was übernommen
wurde und was nicht. Bei einem Konflikt gewinnt der jüngere Stand, bei gleicher
Zeit die höhere Revision. Für einen Variantenbaum gibt es kein sinnvolles
Verschmelzen: ein halb zusammengeführter Baum wäre schlimmer als der Verlust
einer Änderung. Abgelehnte Zeilen stehen in `conflicts`, die App holt sie beim
nächsten `GET` in der Serverfassung ab.

`GET /v1/sync?since=` filtert über `syncedAt`, die Uhr des Servers — nicht über
`updatedAt`, die vom Gerät kommt. Eine nachgehende Geräteuhr würde sonst dazu
führen, dass eine gerade hochgeladene Änderung beim nächsten Abholen fehlt.

Gelöschtes bleibt als Grabstein stehen (`deletedAt`). Ohne ihn käme eine Zeile,
die auf einem zweiten Gerät noch existiert, beim nächsten Abgleich zurück.

## Betrieb

```bash
docker build -t masteropening-backend backend
docker run -d --name masteropening \
  -p 3000:3000 \
  -v masteropening-data:/data \
  -e JWT_SECRET="$(node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))")" \
  masteropening-backend
```

Das Abbild führt beim Start `prisma migrate deploy` aus und legt die Datenbank
im Volume `/data` an. Der Prozess läuft als `node`, nicht als root.

Für TLS gehört ein Reverse-Proxy davor (Caddy oder nginx); `trustProxy` ist
gesetzt, damit die Ratenbegrenzung die echte Adresse des Anrufers sieht und
nicht die des Proxys.

## Auf PostgreSQL wechseln

SQLite trägt diesen Dienst weit: ein Nutzer erzeugt einige Kilobyte, und
Schreibzugriffe kommen selten. Wenn es doch mehr wird, sind es drei Schritte:

1. In `prisma/schema.prisma` `provider = "sqlite"` durch `"postgresql"`
   ersetzen.
2. `DATABASE_URL` auf die Postgres-Adresse setzen.
3. `rm -rf prisma/migrations && npx prisma migrate dev --name init` — die
   bestehende Wanderung ist in SQLite-Dialekt geschrieben.

Am Datenmodell selbst ändert sich nichts: es benutzt keine Eigenheit, die nur
eine der beiden Datenbanken kennt.

## Was nicht drin ist

- **Keine Push-Nachrichten.** Der Push-Token wird entgegengenommen und
  aufbewahrt, aber nicht benutzt. Erinnerungen laufen als lokale
  Benachrichtigungen in der App — für eine Lerngewohnheit das richtige Mittel,
  es funktioniert offline und braucht kein Firebase.
- **Keine Schachlogik.** Der Server prüft kein PGN und kennt keine Stellung. Er
  nimmt das Dokument, wie es kommt.
