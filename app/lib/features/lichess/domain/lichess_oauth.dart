import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Verifizierer und Prüfwert eines PKCE-Vorgangs.
@immutable
class PkcePair {
  const PkcePair({required this.verifier, required this.challenge});

  /// Das Geheimnis, das nur die App kennt.
  final String verifier;

  /// Der Hash davon, der öffentlich mitgeschickt wird.
  final String challenge;
}

/// Fehler im OAuth-Ablauf, den der Nutzer zu sehen bekommt.
class LichessAuthException implements Exception {
  const LichessAuthException(this.message);

  final String message;

  @override
  String toString() => 'LichessAuthException: $message';
}

/// Die festen Größen des Anmeldevorgangs bei Lichess.
///
/// Lichess vergibt keine Client-Geheimnisse: eine mobile App kann keines
/// bewahren. Stattdessen PKCE mit S256 — die App schickt zunächst nur den
/// Hash eines Zufallswerts und beim Einlösen des Codes den Wert selbst.
abstract final class LichessOAuth {
  static const authorizationEndpoint = 'https://lichess.org/oauth';
  static const tokenEndpoint = 'https://lichess.org/api/token';
  static const apiBaseUrl = 'https://lichess.org';

  /// Bei öffentlichen Clients frei wählbar; Lichess zeigt ihn dem Nutzer im
  /// Zustimmungsdialog an.
  static const clientId = 'masteropening.app';

  static const callbackScheme = 'masteropening';
  static const redirectUri = '$callbackScheme://oauth/lichess';

  /// Nur Lesezugriff. Ohne `email:read`, ohne Schreibrechte — die App legt
  /// weder Partien noch Studien an.
  static const scopes = ['preference:read', 'study:read'];

  /// Erzeugt Verifizierer und Prüfwert nach RFC 7636.
  ///
  /// 32 Zufallsbytes ergeben in Base64url 43 Zeichen — das Minimum, das die
  /// Norm verlangt, und zugleich volle 256 Bit Entropie.
  static PkcePair generatePkce({Random? random}) {
    final source = random ?? Random.secure();
    final bytes = List<int>.generate(32, (_) => source.nextInt(256));
    final verifier = _base64Url(bytes);

    return PkcePair(verifier: verifier, challenge: challengeFor(verifier));
  }

  /// Der S256-Prüfwert zu einem Verifizierer.
  static String challengeFor(String verifier) =>
      _base64Url(sha256.convert(utf8.encode(verifier)).bytes);

  /// Ein Zufallswert, der die Antwort dem eigenen Vorgang zuordnet.
  static String generateState({Random? random}) {
    final source = random ?? Random.secure();
    return _base64Url(List<int>.generate(16, (_) => source.nextInt(256)));
  }

  /// Die Adresse, die im Browser geöffnet wird.
  static Uri authorizationUri({
    required PkcePair pkce,
    required String state,
  }) {
    return Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': pkce.challenge,
        'scope': scopes.join(' '),
        'state': state,
      },
    );
  }

  /// Liest den Autorisierungscode aus der Rückleitung.
  ///
  /// Prüft dabei den Zustandswert: ohne diesen Abgleich könnte eine
  /// untergeschobene Rückleitung ein fremdes Konto verbinden.
  static String codeFrom(String callbackUrl, {required String expectedState}) {
    final uri = Uri.parse(callbackUrl);

    if (uri.queryParameters['error'] case final error?) {
      throw LichessAuthException(
        uri.queryParameters['error_description'] ?? error,
      );
    }

    if (uri.queryParameters['state'] != expectedState) {
      throw const LichessAuthException('state mismatch');
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw const LichessAuthException('no authorization code');
    }
    return code;
  }

  /// Der Rumpf der Anfrage, die den Code gegen ein Token tauscht.
  static Map<String, String> tokenRequestBody({
    required String code,
    required String verifier,
  }) {
    return {
      'grant_type': 'authorization_code',
      'code': code,
      'code_verifier': verifier,
      'redirect_uri': redirectUri,
      'client_id': clientId,
    };
  }

  /// Base64url ohne Auffüllzeichen — so verlangt es RFC 7636.
  static String _base64Url(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');
}
