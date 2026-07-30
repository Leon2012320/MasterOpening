/// Werte, die beim Bauen feststehen.
abstract final class AppConfig {
  /// Die Adresse des eigenen Backends.
  ///
  /// Leer, solange keine Instanz läuft — dann bleibt der Abgleich
  /// ausgeschaltet und die App arbeitet rein lokal weiter. Gesetzt wird er
  /// beim Bauen:
  ///
  /// ```bash
  /// flutter build apk --dart-define=API_BASE_URL=https://api.example.org
  /// ```
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Ob es überhaupt einen Server gibt, mit dem sich abgleichen liesse.
  static bool get syncConfigured => apiBaseUrl.isNotEmpty;
}
