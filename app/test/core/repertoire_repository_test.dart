import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';

void main() {
  late AppDatabase db;
  late RepertoireRepository repo;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repo = RepertoireRepository(db);
  });

  tearDown(() => db.close());

  Future<Repertoire> row(int id) async => (await db.repertoireDao.getById(id))!;

  group('Anlegen', () {
    test('speichert den Baum als PGN und zählt Züge und Varianten', () async {
      final tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'])
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4']);

      final id = await repo.create(
        name: 'Offene Spiele',
        side: Side.white,
        tree: tree,
        source: RepertoireSource.manual,
      );

      final saved = await row(id);
      expect(saved.name, 'Offene Spiele');
      expect(saved.side, Side.white);
      expect(saved.nodeCount, 6);
      expect(saved.lineCount, 2);
      expect(PgnIo.parse(saved.pgn).tree, tree);
    });

    test('legt Fortschritt nur für die eigenen Züge an', () async {
      final id = await repo.create(
        name: 'Spanisch',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine([
          'e4',
          'e5',
          'Nf3',
          'Nc6',
          'Bb5',
        ]),
        source: RepertoireSource.manual,
      );

      final progress = await db.progressDao.forRepertoire(id);

      // e4, Nf3, Bb5 — die schwarzen Antworten gibt die App vor.
      expect(progress, hasLength(3));
      expect(
        progress.every((p) => p.state == FsrsState.newCard),
        isTrue,
      );
    });

    test('macht neue Züge sofort fällig', () async {
      final now = DateTime(2026, 7, 29, 20);
      final id = await repo.create(
        name: 'Italienisch',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4']),
        source: RepertoireSource.manual,
        now: now,
      );

      final progress = await db.progressDao.forRepertoire(id);
      expect(progress.single.due, now);
    });

    test('vergibt eine UUID im RFC-4122-Format', () {
      final uuid = RepertoireRepository.newUuid();

      expect(
        uuid,
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
      expect(uuid, isNot(RepertoireRepository.newUuid()));
    });
  });

  group('Bearbeiten', () {
    test('behält den Lernstand unveränderter Züge', () async {
      final id = await repo.create(
        name: 'Spanisch',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine([
          'e4',
          'e5',
          'Nf3',
          'Nc6',
          'Bb5',
        ]),
        source: RepertoireSource.manual,
      );

      // Einen Zug auf „gelernt" setzen.
      final e4Hash = RepertoireTree.hashFor(RepertoireTree.initialFen, [
        'e2e4',
      ]);
      final before = (await db.progressDao.getOne(id, e4Hash))!;
      await db.progressDao.upsert(
        before.copyWith(
          state: FsrsState.review,
          stability: 12.5,
          reps: 4,
          due: DateTime(2026, 8, 15),
        ),
      );

      // Eine weitere Variante ergänzen.
      final saved = await row(id);
      final extended = repo.treeOf(saved).withSanLine([
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bc4',
        'Bc5',
      ]);
      await repo.saveTree(saved, extended);

      final after = (await db.progressDao.getOne(id, e4Hash))!;
      expect(after.state, FsrsState.review);
      expect(after.stability, 12.5);
      expect(after.reps, 4);
      expect(after.due, DateTime(2026, 8, 15));

      // Der neue eigene Zug hat einen frischen Eintrag bekommen.
      expect(await db.progressDao.forRepertoire(id), hasLength(4));
    });

    test('räumt Fortschritt zu gelöschten Zügen weg', () async {
      final id = await repo.create(
        name: 'Zwei Linien',
        side: Side.white,
        tree: const RepertoireTree.empty()
            .withSanLine(['e4', 'e5', 'Nf3'])
            .withSanLine(['d4', 'd5', 'c4']),
        source: RepertoireSource.manual,
      );
      expect(await db.progressDao.forRepertoire(id), hasLength(4));

      final saved = await row(id);
      final tree = repo.treeOf(saved);
      final d4 = tree.nodeAtUciPath(['d2d4'])!;
      await repo.saveTree(saved, tree.withoutNode(d4.pathHash));

      expect(await db.progressDao.forRepertoire(id), hasLength(2));
    });

    test('erhöht die Revision und leert den Zwischenspeicher', () async {
      final id = await repo.create(
        name: 'Test',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4']),
        source: RepertoireSource.manual,
      );

      final first = await row(id);
      expect(first.revision, 0);

      await repo.saveTree(
        first,
        repo.treeOf(first).withSanLine(['d4']),
      );

      final second = await row(id);
      expect(second.revision, 1);
      expect(repo.treeOf(second).children, hasLength(2));
    });
  });

  group('Import', () {
    test('liest PGN samt Warnungen ein', () async {
      final imported = await repo.importPgn(
        pgn: '[Opening "Sizilianisch"]\n\n1. e4 c5 2. Nf6 Nc6 *',
        side: Side.black,
      );

      final saved = await row(imported.id);
      expect(saved.name, 'Sizilianisch');
      expect(saved.side, Side.black);
      expect(imported.result.warnings.single, contains('Nf6'));
      expect(repo.treeOf(saved).nodeCount, 2);
    });

    test('führt einen weiteren Baum ein, ohne zu doppeln', () async {
      final id = await repo.create(
        name: 'Weiß',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4', 'e5', 'Nf3']),
        source: RepertoireSource.manual,
      );

      await repo.mergeInto(
        await row(id),
        const RepertoireTree.empty().withSanLine(['e4', 'c5', 'Nf3']),
      );

      final saved = await row(id);
      expect(repo.treeOf(saved).lines(), hasLength(2));
      expect(saved.lineCount, 2);
      // e4 und die beiden Sf3 — der gemeinsame erste Zug zählt nur einmal.
      expect(await db.progressDao.forRepertoire(id), hasLength(3));
    });
  });

  group('Löschen', () {
    test('löscht weich und blendet aus der Liste aus', () async {
      final id = await repo.create(
        name: 'Weg damit',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4']),
        source: RepertoireSource.manual,
      );

      await repo.delete(id);

      expect(await db.repertoireDao.getAll(), isEmpty);
      expect((await row(id)).deletedAt, isNotNull);
    });

    test('nimmt beim endgültigen Löschen den Fortschritt mit', () async {
      final id = await repo.create(
        name: 'Weg damit',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4']),
        source: RepertoireSource.manual,
      );

      await db.repertoireDao.purge(id);

      expect(await db.progressDao.forRepertoire(id), isEmpty);
    });
  });

  group('Fälligkeiten', () {
    test('zählt fällige Züge je Repertoire', () async {
      final now = DateTime(2026, 7, 29, 20);

      final a = await repo.create(
        name: 'A',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4', 'e5', 'Nf3']),
        source: RepertoireSource.manual,
        now: now,
      );
      final b = await repo.create(
        name: 'B',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['d4']),
        source: RepertoireSource.manual,
        now: now,
      );

      final counts = await db.progressDao.watchDueCounts(until: now).first;

      expect(counts[a], 2);
      expect(counts[b], 1);
    });

    test('lässt Züge aus, die erst später dran sind', () async {
      final now = DateTime(2026, 7, 29, 20);
      final id = await repo.create(
        name: 'A',
        side: Side.white,
        tree: const RepertoireTree.empty().withSanLine(['e4', 'e5', 'Nf3']),
        source: RepertoireSource.manual,
        now: now,
      );

      final rows = await db.progressDao.forRepertoire(id);
      await db.progressDao.upsert(
        rows.first.copyWith(due: now.add(const Duration(days: 3))),
      );

      final due = await db.progressDao.dueForRepertoire(id, until: now);
      expect(due, hasLength(1));
    });
  });

  test('Fremdschlüssel räumen abhängige Zeilen mit weg', () async {
    final id = await repo.create(
      name: 'A',
      side: Side.white,
      tree: const RepertoireTree.empty().withSanLine(['e4']),
      source: RepertoireSource.manual,
    );

    await db.repertoireDao.purge(id);

    expect(await db.progressDao.forRepertoire(id), isEmpty);
  });
}
