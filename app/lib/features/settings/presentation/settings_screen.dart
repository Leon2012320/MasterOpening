import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/engine/data/engine_providers.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/notifications/data/reminder_providers.dart';
import 'package:masteropening/features/settings/data/reminder_sync.dart';
import 'package:masteropening/features/settings/data/repertoire_export.dart';
import 'package:masteropening/features/settings/presentation/widgets/board_style_picker.dart';
import 'package:masteropening/features/settings/presentation/widgets/settings_group.dart';
import 'package:masteropening/features/sync/data/sync_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Liest die Version einmal beim ersten Anzeigen des Tabs.
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Einstellungen-Tab: Darstellung, Sprache, Training, Erinnerungen, Konto,
/// Daten und Über.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final tokens = context.tokens;

    // Jede Änderung an Erinnerungen oder Serie schreibt den Plan neu fort.
    ref.watch(reminderSyncProvider);

    return TabScaffold(
      slivers: [
        SliverBox(
          bottom: AppSpacing.xxl,
          child: ScreenTitle(l10n.tabSettings),
        ),

        // ── Darstellung ────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionAppearance)),
        SliverBox(
          bottom: AppSpacing.md,
          child: AppSegmentedControl<AppThemeMode>(
            expand: true,
            value: settings.themeMode,
            onChanged: controller.setThemeMode,
            segments: [
              AppSegment(value: AppThemeMode.light, label: l10n.themeLight),
              AppSegment(value: AppThemeMode.dark, label: l10n.themeDark),
              AppSegment(value: AppThemeMode.system, label: l10n.themeSystem),
            ],
          ),
        ),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.settingsBoardStyle,
                trailing: BoardStylePicker(
                  value: settings.boardStyle,
                  onChanged: controller.setBoardStyle,
                ),
              ),
              SettingsRow(
                title: l10n.settingsShowCoordinates,
                trailing: AppSwitch(
                  value: settings.showCoordinates,
                  onChanged: (v) => controller.setShowCoordinates(value: v),
                ),
              ),
              SettingsRow(
                title: l10n.settingsBoardAnimations,
                trailing: AppSwitch(
                  value: settings.boardAnimations,
                  onChanged: (v) => controller.setBoardAnimations(value: v),
                ),
              ),
              SettingsRow(
                title: l10n.settingsHaptics,
                trailing: AppSwitch(
                  value: settings.hapticFeedback,
                  onChanged: (v) => controller.setHapticFeedback(value: v),
                ),
              ),
            ],
          ),
        ),

        // ── Training ───────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionTraining)),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.settingsDailyReviewLimit,
                trailing: _Stepper(
                  value: settings.dailyReviewLimit,
                  min: 5,
                  max: 200,
                  step: 5,
                  onChanged: controller.setDailyReviewLimit,
                ),
              ),
              SettingsRow(
                title: l10n.settingsBlitzSeconds,
                trailing: _Stepper(
                  value: settings.blitzSecondsPerMove,
                  min: 1,
                  max: 15,
                  onChanged: controller.setBlitzSecondsPerMove,
                ),
              ),
              SettingsRow(
                title: l10n.settingsAutoPlay,
                trailing: AppSwitch(
                  value: settings.autoPlayOpponentMoves,
                  onChanged: (v) =>
                      controller.setAutoPlayOpponentMoves(value: v),
                ),
              ),
              SettingsRow(
                title: l10n.settingsShowEngineEval,
                subtitle: ref.watch(engineAvailableProvider)
                    ? null
                    : l10n.settingsEngineMissing,
                trailing: AppSwitch(
                  value: settings.showEngineEval,
                  onChanged: ref.watch(engineAvailableProvider)
                      ? (v) => controller.setShowEngineEval(value: v)
                      : null,
                ),
              ),
              SettingsRow(
                title: l10n.settingsEngineElo,
                trailing: _Stepper(
                  value: settings.engineElo,
                  min: 1320,
                  max: 2850,
                  step: 100,
                  onChanged: controller.setEngineElo,
                ),
              ),
            ],
          ),
        ),

        // ── Erinnerungen ───────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionReminders)),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.settingsDailyReminder,
                trailing: AppSwitch(
                  value: settings.dailyReminderEnabled,
                  onChanged: (v) =>
                      unawaited(_toggleDaily(context, ref, enabled: v)),
                ),
              ),
              SettingsRow(
                title: l10n.settingsReminderTime,
                value: _formatMinutes(context, settings.dailyReminderMinutes),
                onTap: settings.dailyReminderEnabled
                    ? () => unawaited(_pickTime(context, ref))
                    : null,
                showChevron: settings.dailyReminderEnabled,
              ),
              SettingsRow(
                title: l10n.settingsStreakRisk,
                trailing: AppSwitch(
                  value: settings.streakRiskReminder,
                  onChanged: (v) => controller.setStreakRiskReminder(value: v),
                ),
              ),
            ],
          ),
        ),

        // ── Konto ──────────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionAccount)),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: _AccountGroup(),
        ),

        // ── Daten ──────────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionData)),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.settingsExport,
                showChevron: true,
                onTap: () => unawaited(_export(context, ref)),
              ),
            ],
          ),
        ),

        // ── Sprache ────────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsLanguage)),
        SliverBox(
          bottom: AppSpacing.xxl,
          child: AppSegmentedControl<String?>(
            expand: true,
            value: settings.languageCode,
            onChanged: controller.setLanguage,
            segments: [
              AppSegment(value: null, label: l10n.languageSystem),
              const AppSegment(value: 'de', label: 'Deutsch'),
              const AppSegment(value: 'en', label: 'English'),
            ],
          ),
        ),

        // ── Über ───────────────────────────────────────────────────────────
        SliverBox(child: SectionLabel(l10n.settingsSectionAbout)),
        SliverBox(
          bottom: AppSpacing.xl,
          child: SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.settingsLicences,
                showChevron: true,
                onTap: () => _showLicences(context),
              ),
            ],
          ),
        ),
        SliverBox(
          top: AppSpacing.sm,
          child: Center(
            child: ref
                .watch(_packageInfoProvider)
                .when(
                  data: (info) => Text(
                    l10n.settingsVersion(
                      '${info.version} (${info.buildNumber})',
                    ),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.textAlpha(0.4),
                    ),
                  ),
                  loading: () => const SizedBox(height: 16),
                  error: (_, _) => const SizedBox(height: 16),
                ),
          ),
        ),
      ],
    );
  }

  /// Beim Einschalten wird zuerst gefragt — ein Schalter, der stumm nichts
  /// bewirkt, weil das System es verbietet, ist schlimmer als keiner.
  static Future<void> _toggleDaily(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(settingsProvider.notifier);

    if (!enabled) {
      await controller.setDailyReminderEnabled(value: false);
      return;
    }

    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();

    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsRemindersDenied)),
      );
      return;
    }

    await controller.setDailyReminderEnabled(value: true);
  }

  static Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.dailyReminderMinutes ~/ 60,
        minute: settings.dailyReminderMinutes % 60,
      ),
    );
    if (picked == null) return;

    await ref.read(settingsProvider.notifier).setDailyReminderTime(picked);
  }

  static Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final shared = await ref.read(repertoireExportProvider).share();
    if (!shared) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportEmpty)),
      );
    }
  }

  static void _showLicences(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppL10n.of(context).appName,
    );
  }

  static String _formatMinutes(BuildContext context, int minutes) {
    final time = DateTime(2026, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat.Hm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(time);
  }
}

/// Konto und Abgleich.
class _AccountGroup extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final lichess = ref.watch(lichessProvider).value;
    final sync = ref.watch(syncProvider).value;

    return SettingsGroup(
      children: [
        SettingsRow(
          title: l10n.tabLichess,
          value: lichess?.account == null
              ? l10n.settingsLichessDisconnected
              : l10n.settingsLichessConnected(lichess!.account!.username),
        ),
        if (sync?.available ?? false) ...[
          SettingsRow(
            title: l10n.settingsSyncNow,
            subtitle: switch (sync?.lastOutcome?.at) {
              final at? => l10n.settingsSyncAt(
                DateFormat.yMMMd(locale).add_Hm().format(at),
              ),
              _ => l10n.settingsSyncNever,
            },
            showChevron: true,
            onTap: sync!.signedIn && !sync.running
                ? () => unawaited(ref.read(syncProvider.notifier).syncNow())
                : null,
          ),
          SettingsRow(
            title: l10n.settingsDeleteAccount,
            destructive: true,
            onTap: () => unawaited(_confirmDelete(context, ref)),
          ),
        ] else
          SettingsRow(
            title: l10n.settingsSyncNow,
            subtitle: l10n.settingsSyncUnavailable,
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccount),
        content: Text(l10n.settingsDeleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(syncRepositoryProvider).deleteAccount();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsDeleteAccountDone)),
    );
  }
}

/// Ein Zahlenwert mit Minus und Plus.
///
/// Kein Schieberegler: die Werte sind grob gestuft, und ein Regler trifft auf
/// dem Telefon ohnehin nicht genau.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final void Function(int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Button(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - step) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tokens.accent,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        _Button(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + step) : null,
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? tokens.textAlpha(0.25) : tokens.text,
        ),
      ),
    );
  }
}
