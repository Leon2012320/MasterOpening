import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/settings/presentation/widgets/board_style_picker.dart';
import 'package:masteropening/features/settings/presentation/widgets/settings_group.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Liest die Version einmal beim ersten Anzeigen des Tabs.
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Einstellungen-Tab. Darstellung und Sprache sind vollständig; Training,
/// Erinnerungen, Konto und Daten kommen mit den Features, zu denen sie
/// gehören.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final tokens = context.tokens;

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
              AppSegment(value: AppThemeMode.black, label: l10n.themeBlack),
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
}
