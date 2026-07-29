import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lichess-Tab. Zeigt vor der Anmeldung nur den Einstieg; Profil, Wertungen
/// und Partienimport folgen mit der OAuth-Anbindung.
class LichessScreen extends ConsumerWidget {
  const LichessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return TabScaffold(
      slivers: [
        SliverBox(
          bottom: AppSpacing.xl,
          child: ScreenTitle(l10n.tabLichess),
        ),
        SliverToBoxAdapter(
          child: EmptyState(
            icon: PhIcons.userCircle,
            title: l10n.lichessNotConnectedTitle,
            message: l10n.lichessNotConnectedMessage,
          ),
        ),
      ],
    );
  }
}
