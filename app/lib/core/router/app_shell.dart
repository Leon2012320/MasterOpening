import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/app_bottom_nav.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Der Rahmen um die vier Tabs. Jeder Tab behält seinen eigenen
/// Navigationsstapel, damit ein Wechsel nach Bibliothek und zurück nicht die
/// halb ausgefüllte Ansicht im Start-Tab verwirft.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;

    final items = [
      AppNavItem(
        icon: PhIcons.house,
        activeIcon: PhIconsFill.house,
        label: l10n.tabHome,
      ),
      AppNavItem(
        icon: PhIcons.books,
        activeIcon: PhIconsFill.books,
        label: l10n.tabLibrary,
      ),
      AppNavItem(
        icon: PhIcons.userCircle,
        activeIcon: PhIconsFill.userCircle,
        label: l10n.tabLichess,
      ),
      AppNavItem(
        icon: PhIcons.gear,
        activeIcon: PhIconsFill.gear,
        label: l10n.tabSettings,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.bg,
      body: _TabTransition(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Ein zweiter Tipp auf den aktiven Tab führt zurück an dessen Wurzel.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Spielt bei jedem Tab-Wechsel ein kurzes Auf- und Einblenden.
///
/// Bewusst kein [AnimatedSwitcher]: der hielte den alten und den neuen
/// `StatefulNavigationShell` gleichzeitig im Baum, und dessen interner
/// GlobalKey duldet das nicht. Hier bleibt der Teilbaum unverändert stehen,
/// es läuft nur die Animation neu an — der Zustand aller vier Tabs überlebt.
class _TabTransition extends StatefulWidget {
  const _TabTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabTransition> createState() => _TabTransitionState();
}

class _TabTransitionState extends State<_TabTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.medium,
    value: 1,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppCurves.enter,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void didUpdateWidget(_TabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      // Bei 0.35 statt bei 0 beginnen: ein vollständiges Ausblenden würde beim
      // Wechsel kurz eine leere Fläche zeigen.
      unawaited(_controller.forward(from: 0.35));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
