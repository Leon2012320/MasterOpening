/// Aufzählungen, die in der Datenbank landen.
///
/// Sie liegen hier und nicht bei ihrem Feature, weil das Schema sie alle
/// braucht und Feature-Ordner sonst gegenseitig voneinander abhängen würden.
/// Gespeichert wird jeweils der `name` — Reihenfolge und Nummerierung dürfen
/// sich also ändern, die Bezeichner nicht.
library;

/// Woher ein Repertoire stammt.
enum RepertoireSource {
  /// Aus der mitgelieferten Bibliothek übernommen.
  library,

  /// Aus einer Lichess-Studie importiert.
  lichessStudy,

  /// Aus einer PGN-Datei oder eingefügtem Text.
  pgnImport,

  /// Von Hand im Editor angelegt.
  manual,

  /// Von der Repertoire-Analyse als Drill erzeugt.
  generatedDrill,
}

/// Die Trainingsarten aus dem Konzept.
enum TrainingMode {
  /// Gewichtet nach Fälligkeit, Spielhäufigkeit und Fehlerquote.
  smart,

  /// Drei Sekunden pro Zug.
  blitz,

  /// Zufallsstellung aus dem Repertoire als Aufgabe.
  puzzle,

  /// Gegen Eröffnungsfallen verteidigen, die nicht im Repertoire stehen.
  trap,

  /// Eine bestimmte Variante gezielt üben.
  variation,
}

/// Zustand einer Karte im Spaced-Repetition-Verfahren (FSRS).
enum FsrsState { newCard, learning, review, relearning }

/// Wie oft eine Aufgabe zurückgesetzt wird.
enum ChallengeKind { daily, weekly }

/// Woher der Hinweis auf eine fehlende Variante kommt.
enum GapSource {
  /// Aus den eigenen importierten Partien.
  ownGames,

  /// Aus der Lichess-Eröffnungsdatenbank.
  explorer,
}

/// Ausgang einer Partie aus Sicht des Nutzers.
enum GameOutcome { win, draw, loss }

/// Zeitkontrolle einer Lichess-Partie.
enum GameSpeed { ultraBullet, bullet, blitz, rapid, classical, correspondence }
