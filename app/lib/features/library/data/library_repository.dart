import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';

/// Liest die mitgelieferte Eröffnungsbibliothek aus den Assets.
///
/// Der Index ist klein und wird einmal komplett geladen; die Variantenbäume
/// liegen in eigenen Dateien und kommen erst dazu, wenn eine Eröffnung
/// geöffnet wird. Alles ist offline verfügbar — die Bibliothek braucht zu
/// keinem Zeitpunkt eine Netzverbindung.
class LibraryRepository {
  LibraryRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const _dir = 'assets/data/openings';

  final AssetBundle _bundle;

  List<LibraryOpeningSummary>? _index;
  final Map<String, LibraryOpening> _openings = {};
  final Map<String, RepertoireTree> _trees = {};

  Future<List<LibraryOpeningSummary>> index() async {
    final cached = _index;
    if (cached != null) return cached;

    final raw = await _bundle.loadString('$_dir/index.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final parsed = [
      for (final entry in list)
        LibraryOpeningSummary.fromJson(entry as Map<String, dynamic>),
    ];

    _index = parsed;
    return parsed;
  }

  Future<LibraryOpening> opening(String id) async {
    final cached = _openings[id];
    if (cached != null) return cached;

    final raw = await _bundle.loadString('$_dir/$id.json');
    final parsed = LibraryOpening.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    _openings[id] = parsed;
    return parsed;
  }

  /// Der Variantenbaum einer Eröffnung.
  Future<RepertoireTree> tree(String id) async {
    final cached = _trees[id];
    if (cached != null) return cached;

    final parsed = PgnIo.parse((await opening(id)).pgn).tree;
    _trees[id] = parsed;
    return parsed;
  }
}

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepository(),
);

/// Der Bibliotheksindex, einmal geladen und danach zwischengespeichert.
final libraryIndexProvider = FutureProvider<List<LibraryOpeningSummary>>(
  (ref) => ref.watch(libraryRepositoryProvider).index(),
);

/// Eine einzelne Eröffnung samt Variantenbaum.
///
/// Den Rückgabetyp von `FutureProvider.family` exportiert Riverpod nicht
/// öffentlich; die Typargumente stehen deshalb nur am Aufruf.
// ignore: specify_nonobvious_property_types
final libraryOpeningProvider = FutureProvider.family<LibraryOpening, String>(
  (ref, id) => ref.watch(libraryRepositoryProvider).opening(id),
);
