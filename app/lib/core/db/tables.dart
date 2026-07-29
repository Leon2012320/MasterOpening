import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart';
import 'package:masteropening/core/db/enums.dart';

/// Felder, die jede synchronisierbare Zeile trägt.
///
/// `deletedAt` statt echtem Löschen: sonst käme eine Zeile, die auf einem
/// zweiten Gerät noch existiert, beim nächsten Abgleich zurück.
mixin SyncableTable on Table {
  /// Über Geräte hinweg stabile Kennung. Die `id` ist nur lokal gültig.
  TextColumn get uuid => text().unique()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Wird bei jeder Änderung erhöht; der Server erkennt daran veraltete Daten.
  IntColumn get revision => integer().withDefault(const Constant(0))();
}

/// Ein Repertoire: Name, Farbe und der Variantenbaum als PGN.
///
/// Der Baum liegt bewusst als PGN-Text und nicht als Zeilen je Zug vor:
/// PGN ist ohnehin das Austauschformat der App, ein Repertoire ist mit
/// einigen hundert Zügen klein genug zum Einlesen in einem Rutsch, und der
/// Abgleich mit dem Server überträgt so ein Dokument statt tausender Zeilen.
/// Der Lernfortschritt hängt nicht daran, sondern an [NodeProgress.pathHash].
class Repertoires extends Table with SyncableTable {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Die Farbe, die der Nutzer in diesem Repertoire spielt.
  TextColumn get side => textEnum<Side>()();

  /// Der Variantenbaum, inklusive Kommentaren und NAGs.
  TextColumn get pgn => text()();

  /// Grundstellung; weicht nur bei Repertoires aus einer Mittelspielstellung
  /// von der Ausgangsstellung ab.
  TextColumn get startFen => text()();

  /// Komma-getrennte ECO-Codes, für Suche und Anzeige.
  TextColumn get ecoCodes => text().withDefault(const Constant(''))();

  TextColumn get source => textEnum<RepertoireSource>()();

  /// Kennung an der Quelle: Bibliotheks-ID, Lichess-Studien-ID, Dateiname.
  TextColumn get sourceRef => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Zwischengespeichert, damit die Startseite nicht jedes Repertoire parsen
  /// muss, nur um eine Zahl anzuzeigen.
  IntColumn get nodeCount => integer().withDefault(const Constant(0))();
  IntColumn get lineCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastTrainedAt => dateTime().nullable()();
}

/// Lernfortschritt je Zug, nach dem FSRS-Verfahren.
class NodeProgress extends Table {
  IntColumn get repertoireId =>
      integer().references(Repertoires, #id, onDelete: KeyAction.cascade)();

  /// SHA-1 über Startstellung und UCI-Zugfolge — siehe `RepertoireTree`.
  TextColumn get pathHash => text().withLength(min: 40, max: 40)();

  TextColumn get state => textEnum<FsrsState>()();

  /// Tage, bis die Erinnerungswahrscheinlichkeit auf 90 % fällt.
  RealColumn get stability => real().withDefault(const Constant(0))();

  /// 1…10; wie schwer der Zug diesem Nutzer fällt.
  RealColumn get difficulty => real().withDefault(const Constant(0))();

  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();

  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {repertoireId, pathHash};
}

/// Eine abgeschlossene Trainingseinheit — Grundlage des Reports.
class TrainingSessions extends Table with SyncableTable {
  IntColumn get id => integer().autoIncrement()();

  /// `null`, wenn über mehrere Repertoires hinweg trainiert wurde.
  IntColumn get repertoireId => integer().nullable().references(
    Repertoires,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get mode => textEnum<TrainingMode>()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get movesTotal => integer().withDefault(const Constant(0))();
  IntColumn get movesCorrect => integer().withDefault(const Constant(0))();

  /// Varianten mit mehr als 75 % richtigen Zügen.
  IntColumn get linesLearned => integer().withDefault(const Constant(0))();

  /// Varianten ohne einen einzigen Fehler.
  IntColumn get linesMastered => integer().withDefault(const Constant(0))();

  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
}

/// Ein einzelner Zugversuch. Feiner als die Sitzung, weil daraus die
/// Fehlerstatistik je Variante und die Gewichtung im Smart-Modus entsteht.
class TrainingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer().references(
    TrainingSessions,
    #id,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get repertoireId => integer()();
  TextColumn get pathHash => text()();

  TextColumn get expectedSan => text()();

  /// `null`, wenn die Zeit abgelaufen ist, ohne dass gezogen wurde.
  TextColumn get playedSan => text().nullable()();

  BoolColumn get correct => boolean()();
  IntColumn get msTaken => integer()();
  DateTimeColumn get attemptedAt => dateTime()();
}

/// Eine von Lichess importierte Partie.
class LichessGames extends Table {
  /// Die Lichess-Partie-ID.
  TextColumn get id => text()();

  TextColumn get pgn => text()();

  /// Die Farbe, mit der der Nutzer gespielt hat.
  TextColumn get side => textEnum<Side>()();

  TextColumn get outcome => textEnum<GameOutcome>()();
  TextColumn get speed => textEnum<GameSpeed>()();

  TextColumn get eco => text().nullable()();
  TextColumn get openingName => text().nullable()();

  TextColumn get opponentName => text().nullable()();
  IntColumn get opponentRating => integer().nullable()();
  IntColumn get ownRating => integer().nullable()();

  IntColumn get plyCount => integer().withDefault(const Constant(0))();
  BoolColumn get rated => boolean().withDefault(const Constant(true))();

  DateTimeColumn get playedAt => dateTime()();
  DateTimeColumn get importedAt => dateTime()();

  /// Ab welchem Halbzug die Partie vom Repertoire abweicht — `null`, solange
  /// die Analyse noch nicht gelaufen ist, `-1`, wenn sie nie abweicht.
  IntColumn get deviationPly => integer().nullable()();
  IntColumn get matchedRepertoireId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Eine häufig gespielte Variante, die im Repertoire fehlt.
class RepertoireGaps extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get repertoireId =>
      integer().references(Repertoires, #id, onDelete: KeyAction.cascade)();

  /// Der Knoten, an dem abgezweigt wird; leer, wenn schon der erste Zug fehlt.
  TextColumn get parentPathHash => text()();

  TextColumn get fen => text()();
  TextColumn get missingSan => text()();
  TextColumn get missingUci => text()();

  /// Wie oft die Lücke aufgetreten ist.
  IntColumn get occurrences => integer().withDefault(const Constant(1))();

  /// Wie viel Punkte sie gekostet hat: 1.0 je verlorener, 0.5 je remisierter
  /// Partie. Häufigkeit mal Verlust ergibt die Dringlichkeit.
  RealColumn get pointsLost => real().withDefault(const Constant(0))();

  TextColumn get source => textEnum<GapSource>()();

  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get detectedAt => dateTime()();
}

/// Tageswerte für Serie, Heatmap, Lernzeit und Genauigkeitsverlauf.
class ActivityDays extends Table {
  /// Ortsdatum als `JJJJ-MM-TT`. Bewusst Text: die Serie richtet sich nach dem
  /// Kalendertag des Nutzers, nicht nach einem Zeitstempel in UTC.
  TextColumn get day => text().withLength(min: 10, max: 10)();

  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get movesTrained => integer().withDefault(const Constant(0))();
  IntColumn get movesCorrect => integer().withDefault(const Constant(0))();
  IntColumn get secondsStudied => integer().withDefault(const Constant(0))();
  IntColumn get sessions => integer().withDefault(const Constant(0))();
  IntColumn get linesMastered => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {day};
}

/// Der Spielerstand. Genau eine Zeile mit `id = 1`.
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get streakCurrent => integer().withDefault(const Constant(0))();
  IntColumn get streakBest => integer().withDefault(const Constant(0))();

  /// Letzter Tag mit Aktivität, als `JJJJ-MM-TT`.
  TextColumn get lastActiveDay => text().nullable()();

  /// Gutschriften, die einen versäumten Tag überbrücken.
  IntColumn get streakFreezes => integer().withDefault(const Constant(2))();

  TextColumn get displayName => text().nullable()();
  TextColumn get lichessUsername => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Freigeschaltete und angefangene Erfolge. Die Definitionen liegen im Code,
/// hier steht nur der Stand des Nutzers.
class AchievementProgress extends Table {
  /// Slug aus dem Erfolgskatalog.
  TextColumn get achievementId => text()();

  IntColumn get progress => integer().withDefault(const Constant(0))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// Ob die Freischalt-Animation schon gezeigt wurde.
  BoolColumn get seen => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {achievementId};
}

/// Tages- und Wochenaufgaben.
class Challenges extends Table {
  /// `<kind>:<periodKey>:<type>`, damit dieselbe Aufgabe je Zeitraum genau
  /// einmal existiert.
  TextColumn get id => text()();

  TextColumn get kind => textEnum<ChallengeKind>()();

  /// Slug des Aufgabentyps aus dem Katalog.
  TextColumn get type => text()();

  /// `JJJJ-MM-TT` für Tages-, `JJJJ-WNN` für Wochenaufgaben.
  TextColumn get periodKey => text()();

  IntColumn get target => integer()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get xpReward => integer()();

  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get claimed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ausgewertete Gegner für die Anti-Vorbereitung.
class OpponentScouts extends Table {
  TextColumn get username => text()();

  /// Ergebnis der Auswertung als JSON — ein Bericht wird immer als Ganzes
  /// gelesen und geschrieben, eine Normalisierung brächte hier nichts.
  TextColumn get reportJson => text()();

  IntColumn get gamesAnalysed => integer().withDefault(const Constant(0))();
  DateTimeColumn get analysedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {username};
}

/// Kleiner Schlüssel-Wert-Speicher für alles, was kein eigenes Schema
/// verdient: Sync-Marken, Zeitpunkt des letzten Partie-Imports, Zähler.
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
