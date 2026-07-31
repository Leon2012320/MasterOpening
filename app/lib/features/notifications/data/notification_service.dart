import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:masteropening/features/notifications/domain/reminder_plan.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Der Text einer Erinnerung. Kommt von aussen, weil er übersetzt sein muss
/// und die Übersetzung am Widget hängt, nicht am Dienst.
typedef ReminderText = ({String title, String body});

/// Plant und löscht die lokalen Benachrichtigungen.
abstract interface class NotificationService {
  /// Ob das Betriebssystem sie überhaupt zulässt.
  Future<bool> requestPermission();

  /// Ersetzt alle geplanten Erinnerungen durch [reminders].
  Future<void> apply(
    List<PlannedReminder> reminders,
    ReminderText Function(ReminderKind kind) textFor,
  );

  Future<void> cancelAll();
}

/// Tut nichts — für Tests und Plattformen ohne Benachrichtigungen.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> apply(
    List<PlannedReminder> reminders,
    ReminderText Function(ReminderKind kind) textFor,
  ) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Lokale Benachrichtigungen über `flutter_local_notifications`.
///
/// Bewusst lokal statt über einen Server: eine Lerngewohnheit braucht keine
/// Push-Infrastruktur, und ohne Firebase bleibt die App leichter und die
/// Datenschutzerklärung kürzer.
class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'masteropening.reminders';
  static const _channelName = 'Erinnerungen';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  Future<void> _ensureInitialised() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();
    // Ohne die Zone des Geräts landet eine „19:30"-Erinnerung in UTC — je
    // nach Standort also mitten in der Nacht.
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Die Erlaubnis wird beim Einschalten des Schalters erfragt, nicht
          // beim Start — dann weiss der Nutzer, wofür.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    _initialised = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialised();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }

    return false;
  }

  @override
  Future<void> apply(
    List<PlannedReminder> reminders,
    ReminderText Function(ReminderKind kind) textFor,
  ) async {
    await _ensureInitialised();
    await cancelAll();

    for (final reminder in reminders) {
      final text = textFor(reminder.kind);

      await _plugin.zonedSchedule(
        id: reminder.id,
        title: text.title,
        body: text.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: _details,
        // Ungenaue Planung reicht: eine Lernerinnerung darf zehn Minuten
        // später kommen, und die genaue Weckfunktion verlangt auf Android
        // eine Sondererlaubnis, die Google eng auslegt.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: reminder.repeatsDaily
            ? DateTimeComponents.time
            : null,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _ensureInitialised();
    await _plugin.cancelAll();
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
    ),
    iOS: DarwinNotificationDetails(),
  );
}

/// Der Dienst dieser Plattform.
NotificationService createNotificationService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return LocalNotificationService();
  }
  return const NoopNotificationService();
}
