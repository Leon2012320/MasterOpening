import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:masteropening/features/sync/domain/sync_payload.dart';

/// Wo die Token des eigenen Servers liegen.
abstract interface class SyncSessionStore {
  Future<SyncSession?> read();
  Future<void> write(SyncSession session);
  Future<void> clear();
}

class SecureSyncSessionStore implements SyncSessionStore {
  const SecureSyncSessionStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const _accessKey = 'sync.accessToken';
  static const _refreshKey = 'sync.refreshToken';

  final FlutterSecureStorage _storage;

  @override
  Future<SyncSession?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);

    if (access == null || refresh == null) return null;
    return SyncSession(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(SyncSession session) async {
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Für Tests und den Desktop-Durchlauf ohne Schlüsselbund.
class InMemorySyncSessionStore implements SyncSessionStore {
  InMemorySyncSessionStore([this._session]);

  SyncSession? _session;

  @override
  Future<SyncSession?> read() async => _session;

  @override
  Future<void> write(SyncSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
