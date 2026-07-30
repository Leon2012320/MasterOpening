import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wo das Lichess-Token liegt.
///
/// Als Schnittstelle, damit Tests nicht am Schlüsselbund des Betriebssystems
/// hängen — der ist in einer Testumgebung schlicht nicht vorhanden.
abstract interface class LichessTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Der Normalfall: verschlüsselt im Keystore beziehungsweise Keychain.
class SecureLichessTokenStore implements LichessTokenStore {
  const SecureLichessTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'lichess.accessToken';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Für Tests und den Desktop-Durchlauf ohne Schlüsselbund.
class InMemoryLichessTokenStore implements LichessTokenStore {
  InMemoryLichessTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
