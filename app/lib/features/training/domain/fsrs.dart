import 'dart:math' as math;

import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Wie gut ein Zug saß.
///
/// FSRS kennt vier Stufen. Beim Eröffnungstraining entstehen sie nicht aus
/// einer Selbsteinschätzung, sondern aus dem, was messbar ist: war der Zug
/// richtig, und wie lange hat er gedauert.
enum ReviewRating {
  /// Falscher Zug oder Zeit abgelaufen.
  again(1),

  /// Richtig, aber es hat gedauert.
  hard(2),

  /// Richtig in normaler Zeit.
  good(3),

  /// Richtig und aus dem Handgelenk.
  easy(4);

  const ReviewRating(this.value);

  final int value;

  bool get isCorrect => this != ReviewRating.again;
}

/// Der Lernstand eines Zuges.
@immutable
class FsrsCard {
  const FsrsCard({
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.due,
    this.lastReview,
    this.reps = 0,
    this.lapses = 0,
  });

  /// Ein Zug, der noch nie abgefragt wurde. Sofort fällig: wer eine Eröffnung
  /// hinzufügt, will sie jetzt lernen.
  factory FsrsCard.fresh(DateTime now) => FsrsCard(
    state: FsrsState.newCard,
    stability: 0,
    difficulty: 0,
    due: now,
  );

  final FsrsState state;

  /// Tage, bis die Erinnerungswahrscheinlichkeit auf 90 % gefallen ist.
  final double stability;

  /// 1 bis 10 — wie schwer dieser Zug diesem Nutzer fällt.
  final double difficulty;

  final DateTime due;
  final DateTime? lastReview;
  final int reps;
  final int lapses;

  /// Wie viele Tage seit der letzten Abfrage vergangen sind.
  double elapsedDays(DateTime now) {
    final last = lastReview;
    if (last == null) return 0;
    final days = now.difference(last).inSeconds / Duration.secondsPerDay;
    return days < 0 ? 0 : days;
  }

  /// Die geschätzte Erinnerungswahrscheinlichkeit zum Zeitpunkt [now].
  ///
  /// Die Potenzfunktion aus FSRS-5: sie fällt anfangs schnell und flacht dann
  /// ab — deutlich näher an echten Vergessenskurven als eine Exponentialfunktion.
  double retrievability(DateTime now) {
    if (state == FsrsState.newCard || stability <= 0) return 0;
    final t = elapsedDays(now);
    return math.pow(1 + Fsrs.factor * t / stability, Fsrs.decay).toDouble();
  }
}

/// Das Free-Spaced-Repetition-Verfahren, auf Eröffnungszüge zugeschnitten.
///
/// Eigene Umsetzung statt eines Pakets: das Verfahren ist überschaubar, die
/// Anbindung an die eigene Bewertungsskala geht so ohne Umweg, und der
/// Lernstand ist das Herz der App — er soll nicht an einer fremden
/// Versionspflege hängen.
///
/// Die Gewichte sind die veröffentlichten FSRS-5-Standardwerte.
abstract final class Fsrs {
  /// Zielwahrscheinlichkeit beim Wiedervorlegen. 0,9 heißt: ein Zug kommt
  /// wieder, wenn die Erinnerung auf 90 % gefallen ist.
  static const requestedRetention = 0.9;

  /// Obergrenze für den Abstand, damit nichts auf Jahre verschwindet.
  static const maximumIntervalDays = 365;

  static const decay = -0.5;
  static final double factor = math.pow(0.9, 1 / decay).toDouble() - 1;

  static const w = <double>[
    0.40255, 1.18385, 3.173, 15.69105, // Anfangsstabilität je Bewertung
    7.1949, 0.5345, 1.4604, // Anfangsschwierigkeit und deren Anpassung
    0.0046, 1.54575, 0.1192, 1.01925, // Stabilität nach richtiger Antwort
    1.9395, 0.11, 0.29605, 2.2698, // Stabilität nach Fehler
    0.2315, 2.9898, 0.51655, 0.6621,
  ];

  /// Verrechnet eine Antwort und liefert den neuen Lernstand.
  static FsrsCard review(
    FsrsCard card,
    ReviewRating rating, {
    required DateTime now,
  }) {
    final next = switch (card.state) {
      FsrsState.newCard => _reviewNew(card, rating, now),
      _ => _reviewExisting(card, rating, now),
    };

    return FsrsCard(
      state: next.state,
      stability: next.stability,
      difficulty: next.difficulty,
      due: next.due,
      lastReview: now,
      reps: card.reps + 1,
      lapses: card.lapses + (rating == ReviewRating.again ? 1 : 0),
    );
  }

  static FsrsCard _reviewNew(FsrsCard card, ReviewRating rating, DateTime now) {
    final stability = _initialStability(rating);
    final difficulty = _initialDifficulty(rating);

    // Ein neu gelernter Zug kommt zunächst innerhalb derselben Sitzung oder
    // am selben Tag wieder — erst danach greifen echte Tagesabstände.
    final (state, due) = switch (rating) {
      ReviewRating.again => (
        FsrsState.learning,
        now.add(const Duration(minutes: 1)),
      ),
      ReviewRating.hard => (
        FsrsState.learning,
        now.add(const Duration(minutes: 6)),
      ),
      ReviewRating.good => (
        FsrsState.learning,
        now.add(const Duration(minutes: 10)),
      ),
      ReviewRating.easy => (
        FsrsState.review,
        now.add(Duration(days: _intervalDays(stability))),
      ),
    };

    return FsrsCard(
      state: state,
      stability: stability,
      difficulty: difficulty,
      due: due,
    );
  }

  static FsrsCard _reviewExisting(
    FsrsCard card,
    ReviewRating rating,
    DateTime now,
  ) {
    final retrievability = card.retrievability(now);
    final difficulty = _nextDifficulty(card.difficulty, rating);

    final stability = rating == ReviewRating.again
        ? _forgetStability(difficulty, card.stability, retrievability)
        : _recallStability(difficulty, card.stability, retrievability, rating);

    if (rating == ReviewRating.again) {
      // Nach einem Fehler wird der Zug nicht auf Tage vertagt, sondern gleich
      // noch einmal geübt — im Eröffnungstraining ist das der ganze Zweck.
      return FsrsCard(
        state: FsrsState.relearning,
        stability: stability,
        difficulty: difficulty,
        due: now.add(const Duration(minutes: 5)),
      );
    }

    return FsrsCard(
      state: FsrsState.review,
      stability: stability,
      difficulty: difficulty,
      due: now.add(Duration(days: _intervalDays(stability))),
    );
  }

  static double _initialStability(ReviewRating rating) =>
      math.max(w[rating.value - 1], 0.1);

  static double _initialDifficulty(ReviewRating rating) =>
      _clampDifficulty(w[4] - math.exp(w[5] * (rating.value - 1)) + 1);

  static double _nextDifficulty(double difficulty, ReviewRating rating) {
    final delta = -w[6] * (rating.value - 3);
    final next = difficulty + delta * (10 - difficulty) / 9;
    // Rückführung zum Mittel: ohne sie driftet die Schwierigkeit über viele
    // Wiederholungen langsam an den Rand.
    final mean = w[7] * _initialDifficulty(ReviewRating.easy);
    return _clampDifficulty(mean + (1 - w[7]) * next);
  }

  static double _recallStability(
    double difficulty,
    double stability,
    double retrievability,
    ReviewRating rating,
  ) {
    final hardPenalty = rating == ReviewRating.hard ? w[15] : 1.0;
    final easyBonus = rating == ReviewRating.easy ? w[16] : 1.0;

    return stability *
        (1 +
            math.exp(w[8]) *
                (11 - difficulty) *
                math.pow(stability, -w[9]) *
                (math.exp((1 - retrievability) * w[10]) - 1) *
                hardPenalty *
                easyBonus);
  }

  static double _forgetStability(
    double difficulty,
    double stability,
    double retrievability,
  ) {
    final next =
        w[11] *
        math.pow(difficulty, -w[12]) *
        (math.pow(stability + 1, w[13]) - 1) *
        math.exp((1 - retrievability) * w[14]);
    // Nach einem Fehler darf die Stabilität nie steigen.
    return math.min(math.max(next, 0.1), stability);
  }

  /// Der Abstand in Tagen, nach dem die Erinnerung auf [requestedRetention]
  /// gefallen ist.
  static int _intervalDays(double stability) {
    final days =
        stability / factor * (math.pow(requestedRetention, 1 / decay) - 1);
    return days.round().clamp(1, maximumIntervalDays);
  }

  static double _clampDifficulty(double value) => value.clamp(1.0, 10.0);

  /// Leitet die Bewertung aus dem ab, was das Training messen kann.
  ///
  /// [expectedMillis] ist die Zeit, die für einen sicher gewussten Zug
  /// angemessen ist. Wer deutlich schneller ist, bekommt `easy`; wer deutlich
  /// länger braucht, `hard`.
  static ReviewRating ratingFor({
    required bool correct,
    required int millis,
    int expectedMillis = 4000,
  }) {
    if (!correct) return ReviewRating.again;
    if (millis <= expectedMillis * 0.4) return ReviewRating.easy;
    if (millis >= expectedMillis * 2) return ReviewRating.hard;
    return ReviewRating.good;
  }
}
