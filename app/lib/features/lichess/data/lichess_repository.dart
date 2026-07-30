import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/features/lichess/data/browser_authenticator.dart';
import 'package:masteropening/features/lichess/data/lichess_api.dart';
import 'package:masteropening/features/lichess/data/lichess_token_store.dart';
import 'package:masteropening/features/lichess/domain/game_import.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/features/lichess/domain/lichess_oauth.dart';
import 'package:meta/meta.dart';

/// Das Ergebnis eines Partie-Imports.
@immutable
class LichessImportResult {
  const LichessImportResult({
    required this.imported,
    required this.skipped,
    required this.total,
  });

  /// Neu oder aktualisiert gespeicherte Partien.
  final int imported;

  /// Übersprungene: abgebrochen, andere Variante, fremde Partie.
  final int skipped;

  /// Wie viele Partien nach dem Import insgesamt in der Datenbank stehen.
  final int total;

  bool get isEmpty => imported == 0;
}

/// Anmeldung, Profil und Partie-Import.
///
/// Offline-first auch hier: das Profil steht als JSON in der Datenbank, die
/// Partien als Zeilen. Ohne Netz zeigt der Tab weiter alles an, was zuletzt
/// bekannt war — nur der Import wartet dann.
class LichessRepository {
  LichessRepository({
    required this._db,
    LichessApi? api,
    LichessTokenStore? tokens,
    BrowserAuthenticator? browser,
  }) : _api = api ?? LichessApi(),
       _tokens = tokens ?? const SecureLichessTokenStore(),
       _browser = browser ?? openInSystemBrowser;

  /// Das zwischengespeicherte Profil.
  static const accountKey = 'lichess.account';

  final AppDatabase _db;
  final LichessApi _api;
  final LichessTokenStore _tokens;
  final BrowserAuthenticator _browser;

  Future<bool> get isConnected async => await _tokens.read() != null;

  /// Das zuletzt bekannte Profil, ohne das Netz zu befragen.
  Future<LichessAccount?> cachedAccount() async {
    final raw = await _db.keyValueDao.get(accountKey);
    if (raw == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return LichessAccount.fromJson(decoded);
  }

  /// Führt den vollständigen Anmeldevorgang durch.
  Future<LichessAccount> connect() async {
    final pkce = LichessOAuth.generatePkce();
    final state = LichessOAuth.generateState();

    final callback = await _browser(
      url: LichessOAuth.authorizationUri(pkce: pkce, state: state),
      callbackScheme: LichessOAuth.callbackScheme,
    );

    final code = LichessOAuth.codeFrom(callback, expectedState: state);
    final token = await _api.exchangeCode(
      code: code,
      verifier: pkce.verifier,
    );

    await _tokens.write(token);

    final account = await _api.account(token);
    await _storeAccount(account);
    return account;
  }

  /// Trennt das Konto: Token zurückziehen, lokal alles entfernen.
  ///
  /// Die importierten Partien gehen mit — sie gehören dem Konto, nicht der
  /// App, und ein Wechsel des Kontos dürfte die Statistik sonst mischen.
  Future<void> disconnect() async {
    if (await _tokens.read() case final token?) {
      // Ein fehlgeschlagener Rückruf darf das Trennen nicht verhindern:
      // wichtiger ist, dass lokal nichts zurückbleibt.
      try {
        await _api.revoke(token);
      } on Object {
        // bewusst verschluckt
      }
    }

    await _tokens.clear();
    await _db.keyValueDao.remove(accountKey);
    await _db.keyValueDao.remove(KeyValueDao.lichessImportedUntil);
    await _db.lichessDao.clear();
    await _db.activityDao.updateProfile(
      const UserProfilesCompanion(lichessUsername: Value(null)),
    );
  }

  /// Holt das Profil neu und schreibt es fort.
  Future<LichessAccount> refreshAccount() async {
    final token = await _requireToken();
    final account = await _api.account(token);
    await _storeAccount(account);
    return account;
  }

  /// Importiert die Partien, die seit dem letzten Mal dazugekommen sind.
  Future<LichessImportResult> importGames({int max = 300}) async {
    final token = await _requireToken();

    final account = await cachedAccount() ?? await refreshAccount();
    final since = await _db.keyValueDao.getDateTime(
      KeyValueDao.lichessImportedUntil,
    );

    final now = DateTime.now();
    final batch = <LichessGame>[];
    var skipped = 0;
    var newest = since;

    final stream = _api.streamGames(
      token: token,
      username: account.username,
      // Eine Sekunde Überlappung: Lichess rechnet `since` in Millisekunden,
      // und eine an der Grenze liegende Partie soll lieber zweimal als gar
      // nicht kommen — der Import ist ohnehin idempotent.
      since: since?.subtract(const Duration(seconds: 1)),
      max: max,
    );

    await for (final json in stream) {
      final game = GameImport.parse(
        json,
        ownUserId: account.id,
        importedAt: now,
      );

      if (game == null) {
        skipped++;
        continue;
      }

      batch.add(game);
      if (newest == null || game.playedAt.isAfter(newest)) {
        newest = game.playedAt;
      }
    }

    await _db.lichessDao.upsertAll(batch);
    if (newest != null) {
      await _db.keyValueDao.setDateTime(
        KeyValueDao.lichessImportedUntil,
        newest,
      );
    }

    return LichessImportResult(
      imported: batch.length,
      skipped: skipped,
      total: await _db.lichessDao.count(),
    );
  }

  Future<void> _storeAccount(LichessAccount account) async {
    await _db.keyValueDao.set(accountKey, jsonEncode(account.toJson()));
    await _db.activityDao.updateProfile(
      UserProfilesCompanion(lichessUsername: Value(account.username)),
    );
  }

  Future<String> _requireToken() async {
    final token = await _tokens.read();
    if (token == null) {
      throw const LichessAuthException('not connected');
    }
    return token;
  }
}
