import 'dart:convert';
import 'dart:math';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/features/training/domain/opening_trap.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';

/// Liest die mitgelieferten Eröffnungsfallen.
class TrapRepository {
  TrapRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _path = 'assets/data/traps.json';

  final AssetBundle _bundle;
  List<OpeningTrap>? _cache;

  Future<List<OpeningTrap>> all() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(_path);
    final parsed = [
      for (final entry in jsonDecode(raw) as List<dynamic>)
        OpeningTrap.fromJson(entry as Map<String, dynamic>),
    ];
    _cache = parsed;
    return parsed;
  }

  /// Stellt Fallen als Trainingsaufgaben zusammen.
  ///
  /// Ausgewählt wird nach den Farben, die der Nutzer in seinen Repertoires
  /// spielt — eine Falle für Weiss zu üben, wenn man nur Schwarz spielt, wäre
  /// verschenkte Zeit. Ohne Repertoire kommen beide Farben.
  Future<List<TrainingLine>> asTrainingLines({
    required Set<Side> sides,
    required String languageCode,
    int maxLines = 8,
    Random? random,
  }) async {
    final pool =
        (await all())
            .where((trap) => sides.isEmpty || sides.contains(trap.side))
            .toList()
          ..shuffle(random ?? Random());

    final lines = <TrainingLine>[];
    for (final trap in pool.take(maxLines)) {
      final tree = PgnIo.parse(trap.pgn).tree;
      final line = tree.lines().firstOrNull;
      if (line == null) continue;

      lines.add(
        TrainingLine(
          // Fallen gehören zu keinem Repertoire. Die negative Kennung hält sie
          // aus dem Lernstand heraus — für einen Zug, der nicht im Repertoire
          // steht, gibt es nichts zu wiederholen.
          repertoireId: TrainingLine.noRepertoire,
          repertoireName: trap.name(languageCode),
          side: trap.side,
          startFen: tree.startFen,
          line: line,
          weight: 1,
          askFromPly: trap.askFromPly,
          trapName: trap.name(languageCode),
          trapExplanation: trap.why(languageCode),
        ),
      );
    }
    return lines;
  }
}

final trapRepositoryProvider = Provider<TrapRepository>(
  (ref) => TrapRepository(),
);
