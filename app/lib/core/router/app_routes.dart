/// Alle Pfade an einer Stelle. Kein Bildschirm baut Routen als String-Literal
/// zusammen — Tippfehler in Navigationspfaden fallen sonst erst zur Laufzeit
/// auf.
abstract final class Routes {
  // ── Die vier Tabs ─────────────────────────────────────────────────────────
  static const home = '/home';
  static const library = '/library';
  static const lichess = '/lichess';
  static const settings = '/settings';

  // ── Bibliothek ────────────────────────────────────────────────────────────
  static const libraryDetailName = 'libraryDetail';
  static String libraryDetail(String openingId) => '$library/$openingId';

  // ── Repertoire ────────────────────────────────────────────────────────────
  static const repertoireImportName = 'repertoireImport';
  static const repertoireImport = '$home/import';

  static const repertoireLearnName = 'repertoireLearn';
  static String repertoireLearn(int repertoireId) =>
      '$home/repertoire/$repertoireId/learn';

  static const repertoireEditName = 'repertoireEdit';
  static String repertoireEdit(int repertoireId) =>
      '$home/repertoire/$repertoireId/edit';

  // ── Training ──────────────────────────────────────────────────────────────
  static const trainingSetupName = 'trainingSetup';
  static String trainingSetup(int repertoireId) =>
      '$home/repertoire/$repertoireId/train';

  static const trainingSessionName = 'trainingSession';
  static const trainingReportName = 'trainingReport';

  // ── Statistik & Gamification ──────────────────────────────────────────────
  static const statsName = 'stats';
  static const stats = '$home/stats';

  static const achievementsName = 'achievements';
  static const achievements = '$home/achievements';

  // ── Lichess ───────────────────────────────────────────────────────────────
  static const lichessGaps = '$lichess/gaps';
  static const antiPrep = '$lichess/anti-prep';
  static const styleAdvice = '$lichess/style';
}
