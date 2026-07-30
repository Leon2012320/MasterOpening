import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/training/domain/fsrs.dart';

final _now = DateTime(2026, 7, 30, 20);

void main() {
  group('Neuer Zug', () {
    test('ist sofort fällig und hat noch keinen Lernstand', () {
      final card = FsrsCard.fresh(_now);

      expect(card.state, FsrsState.newCard);
      expect(card.due, _now);
      expect(card.stability, 0);
      expect(card.reps, 0);
      expect(card.retrievability(_now), 0);
    });

    test(
      'kommt nach der ersten richtigen Antwort noch am selben Tag wieder',
      () {
        final card = Fsrs.review(
          FsrsCard.fresh(_now),
          ReviewRating.good,
          now: _now,
        );

        expect(card.state, FsrsState.learning);
        expect(card.due.difference(_now).inHours, lessThan(1));
        expect(card.reps, 1);
        expect(card.stability, greaterThan(0));
      },
    );

    test('darf nach „leicht" gleich in echte Tagesabstände', () {
      final card = Fsrs.review(
        FsrsCard.fresh(_now),
        ReviewRating.easy,
        now: _now,
      );

      expect(card.state, FsrsState.review);
      expect(card.due.difference(_now).inDays, greaterThanOrEqualTo(1));
    });

    test('gibt bei besserer Bewertung mehr Stabilität', () {
      double stabilityFor(ReviewRating rating) =>
          Fsrs.review(FsrsCard.fresh(_now), rating, now: _now).stability;

      expect(
        stabilityFor(ReviewRating.again),
        lessThan(stabilityFor(ReviewRating.hard)),
      );
      expect(
        stabilityFor(ReviewRating.hard),
        lessThan(stabilityFor(ReviewRating.good)),
      );
      expect(
        stabilityFor(ReviewRating.good),
        lessThan(stabilityFor(ReviewRating.easy)),
      );
    });
  });

  group('Wiederholung', () {
    /// Ein Zug, der schon ein paar Mal saß und heute wieder dran ist.
    FsrsCard established() => FsrsCard(
      state: FsrsState.review,
      stability: 10,
      difficulty: 5,
      due: _now,
      lastReview: _now.subtract(const Duration(days: 10)),
      reps: 3,
    );

    test('verlängert den Abstand nach einer richtigen Antwort', () {
      final card = established();
      final next = Fsrs.review(card, ReviewRating.good, now: _now);

      expect(next.state, FsrsState.review);
      expect(next.stability, greaterThan(card.stability));
      expect(next.due.difference(_now).inDays, greaterThan(10));
    });

    test('holt einen Fehler sofort zurück, statt ihn zu vertagen', () {
      final card = established();
      final next = Fsrs.review(card, ReviewRating.again, now: _now);

      expect(next.state, FsrsState.relearning);
      expect(next.due.difference(_now).inMinutes, lessThanOrEqualTo(10));
      expect(next.lapses, 1);
    });

    test('lässt die Stabilität nach einem Fehler nie steigen', () {
      final card = established();
      final next = Fsrs.review(card, ReviewRating.again, now: _now);

      expect(next.stability, lessThanOrEqualTo(card.stability));
      expect(next.stability, greaterThan(0));
    });

    test(
      'macht einen Zug nach „schwer" schwieriger, nach „leicht" leichter',
      () {
        final card = established();

        expect(
          Fsrs.review(card, ReviewRating.hard, now: _now).difficulty,
          greaterThan(card.difficulty),
        );
        expect(
          Fsrs.review(card, ReviewRating.easy, now: _now).difficulty,
          lessThan(card.difficulty),
        );
      },
    );

    test('hält die Schwierigkeit im Bereich 1 bis 10', () {
      var card = established();
      for (var i = 0; i < 60; i++) {
        card = Fsrs.review(card, ReviewRating.again, now: _now);
        expect(card.difficulty, inInclusiveRange(1, 10));
      }
      for (var i = 0; i < 60; i++) {
        card = Fsrs.review(card, ReviewRating.easy, now: _now);
        expect(card.difficulty, inInclusiveRange(1, 10));
      }
    });

    test('deckelt den Abstand bei einem Jahr', () {
      var card = established();
      var now = _now;

      for (var i = 0; i < 40; i++) {
        card = Fsrs.review(card, ReviewRating.easy, now: now);
        expect(
          card.due.difference(now).inDays,
          lessThanOrEqualTo(Fsrs.maximumIntervalDays),
        );
        now = card.due;
      }
    });
  });

  group('Erinnerungswahrscheinlichkeit', () {
    test('fällt mit der Zeit und bleibt zwischen 0 und 1', () {
      final card = FsrsCard(
        state: FsrsState.review,
        stability: 10,
        difficulty: 5,
        due: _now,
        lastReview: _now,
      );

      final direkt = card.retrievability(_now);
      final nachFuenf = card.retrievability(_now.add(const Duration(days: 5)));
      final nachHundert = card.retrievability(
        _now.add(const Duration(days: 100)),
      );

      expect(direkt, closeTo(1, 0.001));
      expect(nachFuenf, lessThan(direkt));
      expect(nachHundert, lessThan(nachFuenf));
      expect(nachHundert, greaterThan(0));
    });

    test('liegt nach genau einer Stabilitätsspanne bei der Zielquote', () {
      final card = FsrsCard(
        state: FsrsState.review,
        stability: 10,
        difficulty: 5,
        due: _now,
        lastReview: _now,
      );

      expect(
        card.retrievability(_now.add(const Duration(days: 10))),
        closeTo(Fsrs.requestedRetention, 0.01),
      );
    });
  });

  group('Bewertung aus dem Trainingsverlauf', () {
    test('ein falscher Zug ist immer „nochmal"', () {
      expect(
        Fsrs.ratingFor(correct: false, millis: 500),
        ReviewRating.again,
      );
    });

    test('schnell und richtig ist „leicht"', () {
      expect(
        Fsrs.ratingFor(correct: true, millis: 900),
        ReviewRating.easy,
      );
    });

    test('langsam und richtig ist „schwer"', () {
      expect(
        Fsrs.ratingFor(correct: true, millis: 9000),
        ReviewRating.hard,
      );
    });

    test('normal schnell ist „gut"', () {
      expect(
        Fsrs.ratingFor(correct: true, millis: 3000),
        ReviewRating.good,
      );
    });
  });
}
