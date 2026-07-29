import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Tageszeitabhängige Begrüßung, wie sie der Entwurf auf dem Start-Tab zeigt.
String greetingFor(AppL10n l10n, DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return l10n.greetingMorning;
  if (hour >= 11 && hour < 17) return l10n.greetingDay;
  if (hour >= 17 && hour < 23) return l10n.greetingEvening;
  return l10n.greetingNight;
}
