import 'package:dio/dio.dart';
import 'package:masteropening/core/config/app_config.dart';
import 'package:masteropening/features/sync/domain/sync_payload.dart';

/// Fehler, die der Abgleich sichtbar machen darf.
class SyncException implements Exception {
  const SyncException(this.message, {this.isAuthFailure = false});

  final String message;

  /// Der Server hat das Zugriffstoken abgelehnt — dann hilft nur Erneuern
  /// oder neu anmelden.
  final bool isAuthFailure;

  @override
  String toString() => 'SyncException: $message';
}

/// Der Zugriff auf das eigene Backend.
class SyncApi {
  SyncApi({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
              // Fehlerstatus selbst auswerten: der Server schickt dazu eine
              // Erklärung, die in die Meldung gehört.
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  final Dio _dio;

  /// Löst das Lichess-Token beim eigenen Server ein.
  Future<SyncSession> signInWithLichess(String lichessToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/lichess',
      data: {'lichessToken': lichessToken},
    );
    return SyncSession.fromJson(_ok(response));
  }

  Future<SyncSession> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return SyncSession.fromJson(_ok(response));
  }

  Future<PullResponse> pull({
    required String accessToken,
    DateTime? since,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/sync',
      queryParameters: {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
      options: _authorized(accessToken),
    );
    return PullResponse.fromJson(_ok(response));
  }

  Future<PushResponse> push(
    PushPayload payload, {
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/sync',
      data: payload.toJson(),
      options: _authorized(accessToken),
    );
    return PushResponse.fromJson(_ok(response));
  }

  Future<void> registerDevice({
    required String accessToken,
    required String installationId,
    required String platform,
    String? appVersion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/devices',
      data: {
        'installationId': installationId,
        'platform': platform,
        'appVersion': ?appVersion,
      },
      options: _authorized(accessToken),
    );
    _ok(response);
  }

  /// Kontolöschung. Der Server entfernt alle Zeilen; lokal bleibt alles, bis
  /// der Nutzer auch das löscht.
  Future<void> deleteAccount(String accessToken) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/v1/me',
      options: _authorized(accessToken),
    );
    if (response.statusCode != 204) _ok(response);
  }

  static Options _authorized(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  /// Wirft, wenn der Server nicht mitspielt, und liefert sonst den Rumpf.
  static Map<String, dynamic> _ok(Response<Map<String, dynamic>> response) {
    final status = response.statusCode ?? 0;

    if (status == 401 || status == 403) {
      throw SyncException(
        _messageOf(response) ?? 'Anmeldung abgelehnt',
        isAuthFailure: true,
      );
    }
    if (status >= 400) {
      throw SyncException(_messageOf(response) ?? 'Server antwortete $status');
    }

    return response.data ?? const {};
  }

  static String? _messageOf(Response<Map<String, dynamic>> response) =>
      response.data?['message'] as String?;
}
