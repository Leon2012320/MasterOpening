import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// Öffnet die Zustimmungsseite und liefert die Rückleitungsadresse samt Code.
///
/// Als Funktionstyp und nicht fest verdrahtet, weil `FlutterWebAuth2` einen
/// Plattformkanal braucht: im Test gibt es keinen Browser, der zurückkäme.
typedef BrowserAuthenticator =
    Future<String> Function({
      required Uri url,
      required String callbackScheme,
    });

/// Der Normalfall: der Systembrowser des Geräts.
Future<String> openInSystemBrowser({
  required Uri url,
  required String callbackScheme,
}) {
  // Ohne `preferEphemeral` bleibt die Lichess-Sitzung des Browsers erhalten —
  // wer dort angemeldet ist, muss nichts eintippen.
  return FlutterWebAuth2.authenticate(
    url: url.toString(),
    callbackUrlScheme: callbackScheme,
  );
}
