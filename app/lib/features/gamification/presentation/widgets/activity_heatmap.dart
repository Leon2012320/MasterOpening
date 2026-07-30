import 'package:flutter/material.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Die Aktivitäts-Heatmap: ein Kästchen je Tag, Wochen als Spalten.
///
/// Wie bei GitHub, weil das Muster dort gelernt ist — man sieht auf einen
/// Blick, ob die Gewohnheit trägt, ohne eine Zahl lesen zu müssen.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    required this.days,
    required this.today,
    this.frozenDays = const {},
    this.weeks = 20,
    super.key,
  });

  final List<ActivityDay> days;
  final DateTime today;

  /// Tage, die ein Schutztag überbrückt hat — sie bekommen eine Kontur statt
  /// einer Füllung.
  final Set<String> frozenDays;

  final int weeks;

  static const _cell = 11.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final byDay = {for (final day in days) day.day: day};

    // Die Skala richtet sich am eigenen Höchstwert aus: wer täglich zehn
    // Minuten übt, soll ein volles Muster sehen und nicht lauter blasse
    // Kästchen, nur weil andere mehr machen.
    final peak = days.isEmpty
        ? 1
        : days.map((d) => d.movesTrained).reduce((a, b) => a > b ? a : b);

    // Bis zum Ende der laufenden Woche auffüllen, damit die letzte Spalte
    // nicht abgeschnitten wirkt.
    final end = today.add(Duration(days: 7 - today.weekday));
    final start = end.subtract(Duration(days: weeks * 7 - 1));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var week = 0; week < weeks; week++)
            Padding(
              padding: const EdgeInsets.only(right: _gap),
              child: Column(
                children: [
                  for (var weekday = 0; weekday < 7; weekday++)
                    _cellFor(
                      context,
                      date: start.add(Duration(days: week * 7 + weekday)),
                      byDay: byDay,
                      peak: peak,
                      tokens: tokens,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cellFor(
    BuildContext context, {
    required DateTime date,
    required Map<String, ActivityDay> byDay,
    required int peak,
    required AppTokens tokens,
  }) {
    final key = ActivityDao.dayKey(date);
    final isFuture = date.isAfter(today);
    final entry = byDay[key];
    final frozen = frozenDays.contains(key);

    // Fünf Stufen: nichts, wenig, mittel, viel, sehr viel.
    final level = entry == null || entry.movesTrained == 0
        ? 0
        : 1 + ((entry.movesTrained / peak) * 3).round().clamp(0, 3);

    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Tooltip(
        message: entry == null
            ? key
            : '$key · ${AppL10n.of(context).homeMovesTotal(entry.movesTrained)}',
        child: Container(
          width: _cell,
          height: _cell,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isFuture
                ? Colors.transparent
                : frozen
                ? Colors.transparent
                : tokens.heatScale[level],
            border: frozen
                ? Border.all(color: tokens.accent.withValues(alpha: 0.6))
                : null,
          ),
        ),
      ),
    );
  }
}
