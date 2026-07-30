import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/features/lichess/domain/lichess_oauth.dart';

/// Der Zugriff auf die Lichess-API.
///
/// Bewusst dünn: alles, was eine Entscheidung trifft, steht im Domänenteil und
/// ist ohne Netz prüfbar. Hier bleiben Adressen, Kopfzeilen und das Zerlegen
/// des NDJSON-Stroms.
class LichessApi {
  LichessApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: LichessOAuth.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;

  /// Tauscht den Autorisierungscode gegen ein Zugriffstoken.
  Future<String> exchangeCode({
    required String code,
    required String verifier,
  }) async {
    final response = await _dio.postUri<Map<String, dynamic>>(
      Uri.parse(LichessOAuth.tokenEndpoint),
      data: LichessOAuth.tokenRequestBody(code: code, verifier: verifier),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final token = response.data?['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const LichessAuthException('no access token in response');
    }
    return token;
  }

  /// Das Profil des angemeldeten Kontos.
  Future<LichessAccount> account(String token) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/account',
      options: _authorized(token),
    );

    final json = response.data;
    if (json == null) {
      throw const LichessAuthException('empty account response');
    }
    return LichessAccount.fromJson(json);
  }

  /// Die Partien eines Nutzers als Strom einzelner JSON-Objekte.
  ///
  /// Lichess liefert sie als NDJSON — eine Partie je Zeile. Das erlaubt, den
  /// Import laufend zu verbuchen, statt erst Megabytes zu sammeln.
  Stream<Map<String, dynamic>> streamGames({
    required String token,
    required String username,
    DateTime? since,
    int max = 300,
  }) async* {
    final response = await _dio.get<ResponseBody>(
      '/api/games/user/$username',
      queryParameters: {
        'max': max,
        'opening': true,
        'pgnInJson': true,
        'rated': true,
        if (since != null) 'since': since.millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/x-ndjson',
        },
      ),
    );

    final body = response.data;
    if (body == null) return;

    final lines = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) yield decoded;
    }
  }

  /// Zieht das Token zurück. Nach dem Trennen soll die App keinen Zugriff
  /// mehr haben, auch wenn jemand die Kopie im Speicher rettet.
  Future<void> revoke(String token) async {
    await _dio.delete<void>('/api/token', options: _authorized(token));
  }

  static Options _authorized(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});
}
