import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/lichess/domain/game_import.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/features/lichess/domain/lichess_oauth.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';

/// Eine Partie, wie die Lichess-API sie liefert.
Map<String, dynamic> gameJson({
  String id = 'abc12345',
  String status = 'mate',
  String variant = 'standard',
  String speed = 'blitz',
  String? winner = 'white',
  String whiteId = 'leon',
  String blackId = 'gegner',
  String opening = 'Sicilian Defense: Najdorf Variation',
  String eco = 'B90',
}) {
  return {
    'id': id,
    'rated': true,
    'variant': variant,
    'speed': speed,
    'status': status,
    'createdAt': DateTime(2026, 7, 20).millisecondsSinceEpoch,
    'players': {
      'white': {
        'user': {'id': whiteId, 'name': whiteId},
        'rating': 1800,
      },
      'black': {
        'user': {'id': blackId, 'name': blackId},
        'rating': 1750,
      },
    },
    'winner': ?winner,
    'opening': {'eco': eco, 'name': opening, 'ply': 6},
    'moves': 'e4 c5 Nf3 d6 d4 cxd4',
    'pgn': '[Event "Rated blitz game"]\n\n1. e4 c5 2. Nf3 d6 3. d4 cxd4',
  };
}

void main() {
  final importedAt = DateTime(2026, 7, 30);

  group('OAuth mit PKCE', () {
    test('der Verifizierer ist lang genug und URL-sicher', () {
      final pkce = LichessOAuth.generatePkce(random: Random(1));

      expect(pkce.verifier.length, inInclusiveRange(43, 128));
      expect(pkce.verifier, matches(RegExp(r'^[A-Za-z0-9\-._~]+$')));
      expect(pkce.challenge, isNot(pkce.verifier));
    });

    test('der Prüfwert ist der S256-Hash, ohne Auffüllzeichen', () {
      // Das Beispiel aus RFC 7636, Anhang B.
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expected = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

      expect(LichessOAuth.challengeFor(verifier), expected);
    });

    test('die Adresse enthält alles, was der Ablauf braucht', () {
      final uri = LichessOAuth.authorizationUri(
        pkce: LichessOAuth.generatePkce(random: Random(2)),
        state: 'xyz',
      );

      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(uri.queryParameters['redirect_uri'], LichessOAuth.redirectUri);
      expect(uri.queryParameters['scope'], 'preference:read study:read');
      expect(uri.queryParameters['state'], 'xyz');
    });

    test('liest den Code aus der Rückleitung', () {
      final code = LichessOAuth.codeFrom(
        'masteropening://oauth/lichess?code=42&state=xyz',
        expectedState: 'xyz',
      );

      expect(code, '42');
    });

    test('ein fremder Zustandswert wird abgewiesen', () {
      expect(
        () => LichessOAuth.codeFrom(
          'masteropening://oauth/lichess?code=42&state=fremd',
          expectedState: 'xyz',
        ),
        throwsA(isA<LichessAuthException>()),
      );
    });

    test('eine abgelehnte Zustimmung wird als Fehler gemeldet', () {
      expect(
        () => LichessOAuth.codeFrom(
          'masteropening://oauth/lichess?error=access_denied&state=xyz',
          expectedState: 'xyz',
        ),
        throwsA(isA<LichessAuthException>()),
      );
    });
  });

  group('Konto', () {
    test('liest Profil und Wertungen', () {
      final account = LichessAccount.fromJson({
        'id': 'leon',
        'username': 'Leon',
        'title': 'FM',
        'patron': true,
        'createdAt': DateTime(2020, 3).millisecondsSinceEpoch,
        'count': const {'all': 1234},
        'perfs': const {
          'blitz': {'games': 800, 'rating': 1850, 'prog': 12},
          'rapid': {'games': 120, 'rating': 1900, 'prov': true},
          'puzzle': {'rating': 2100},
          'correspondence': {'games': 0, 'rating': 1500},
        },
      });

      expect(account.username, 'Leon');
      expect(account.title, 'FM');
      expect(account.gameCount, 1234);
      expect(account.perfs.containsKey('puzzle'), isFalse);

      // Nur gespielte Zeitkontrollen, in Lichess-Reihenfolge.
      expect([for (final p in account.ratedPerfs) p.key], ['blitz', 'rapid']);
      expect(account.perfs['rapid']!.provisional, isTrue);
    });

    test('übersteht den Weg durch JSON unverändert', () {
      final original = LichessAccount.fromJson(const {
        'id': 'leon',
        'username': 'Leon',
        'count': {'all': 7},
        'perfs': {
          'blitz': {'games': 7, 'rating': 1600},
        },
      });

      final restored = LichessAccount.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.username, original.username);
      expect(restored.gameCount, 7);
      expect(restored.perfs['blitz']!.rating, 1600);
    });
  });

  group('Partie-Import', () {
    test('erkennt eigene Farbe, Ausgang und Eröffnung', () {
      final game = GameImport.parse(
        gameJson(),
        ownUserId: 'leon',
        importedAt: importedAt,
      );

      expect(game, isNotNull);
      expect(game!.side, Side.white);
      expect(game.outcome, GameOutcome.win);
      expect(game.eco, 'B90');
      expect(game.plyCount, 6);
      expect(game.opponentName, 'gegner');
      expect(game.ownRating, 1800);
    });

    test('dreht den Ausgang für Schwarz um', () {
      final game = GameImport.parse(
        gameJson(),
        ownUserId: 'gegner',
        importedAt: importedAt,
      );

      expect(game!.side, Side.black);
      expect(game.outcome, GameOutcome.loss);
      expect(game.opponentName, 'leon');
    });

    test('ohne Sieger ist es ein Remis', () {
      final game = GameImport.parse(
        gameJson(winner: null, status: 'draw'),
        ownUserId: 'leon',
        importedAt: importedAt,
      );

      expect(game!.outcome, GameOutcome.draw);
    });

    test('abgebrochene Partien und fremde Varianten zählen nicht', () {
      expect(
        GameImport.parse(
          gameJson(status: 'aborted'),
          ownUserId: 'leon',
          importedAt: importedAt,
        ),
        isNull,
      );
      expect(
        GameImport.parse(
          gameJson(variant: 'atomic'),
          ownUserId: 'leon',
          importedAt: importedAt,
        ),
        isNull,
      );
    });

    test('eine Partie ohne den Nutzer wird verworfen', () {
      expect(
        GameImport.parse(
          gameJson(),
          ownUserId: 'jemandanderes',
          importedAt: importedAt,
        ),
        isNull,
      );
    });

    test('der Computergegner bekommt einen Namen', () {
      final json = gameJson()
        ..['players'] = {
          'white': {
            'user': {'id': 'leon', 'name': 'leon'},
            'rating': 1800,
          },
          'black': {'aiLevel': 5},
        };

      final game = GameImport.parse(
        json,
        ownUserId: 'leon',
        importedAt: importedAt,
      );

      expect(game!.opponentName, 'Stockfish 5');
    });
  });

  group('Eröffnungsstatistik', () {
    test('fasst nach Familie zusammen, nicht nach Variante', () {
      expect(
        OpeningStats.familyOf('Sicilian Defense: Najdorf, English Attack'),
        'Sicilian Defense',
      );
      expect(OpeningStats.familyOf('Bird Opening'), 'Bird Opening');
      expect(OpeningStats.familyOf(null), OpeningStats.unknownFamily);
    });

    test('zählt Bilanz und Punkteausbeute je Farbe getrennt', () {
      final games = [
        for (var i = 0; i < 3; i++)
          GameImport.parse(
            gameJson(id: 'w$i'),
            ownUserId: 'leon',
            importedAt: importedAt,
          )!,
        for (var i = 0; i < 2; i++)
          GameImport.parse(
            gameJson(id: 'b$i'),
            ownUserId: 'gegner',
            importedAt: importedAt,
          )!,
      ];

      final stats = OpeningStats.from(games);

      expect(stats.length, 2, reason: 'Weiß und Schwarz getrennt');

      final asWhite = stats.firstWhere((s) => s.side == Side.white);
      expect(asWhite.games, 3);
      expect(asWhite.wins, 3);
      expect(asWhite.score, 1.0);

      final asBlack = stats.firstWhere((s) => s.side == Side.black);
      expect(asBlack.losses, 2);
      expect(asBlack.score, 0.0);
    });

    test('einzelne Partien fallen unter die Schwelle', () {
      final games = [
        GameImport.parse(
          gameJson(),
          ownUserId: 'leon',
          importedAt: importedAt,
        )!,
      ];

      expect(OpeningStats.from(games), isEmpty);
      expect(OpeningStats.from(games, threshold: 1), hasLength(1));
    });

    test(
      'die schwächsten Eröffnungen zählen verlorene Punkte, keine Quote',
      () {
        const oftenLost = OpeningStat(
          family: 'Französisch',
          side: Side.white,
          eco: 'C00',
          wins: 4,
          draws: 0,
          losses: 16, // 16 verlorene Punkte
        );
        const rarelyLost = OpeningStat(
          family: 'Skandinavisch',
          side: Side.white,
          eco: 'B01',
          wins: 0,
          draws: 0,
          losses: 2, // schlechtere Quote, aber nur 2 Punkte
        );

        final ranked = OpeningStats.weakest([rarelyLost, oftenLost]);

        expect(ranked.first.family, 'Französisch');
      },
    );
  });
}
