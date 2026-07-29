import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Der Rahmen, in dem jeder der vier Tabs steckt.
///
/// Der Entwurf gibt dem Inhaltsbereich `padding: 56px 18px 14px`. Die 56 px
/// oben sind Statusleiste plus Luft — hier kommt die Statusleiste von
/// [SafeArea], die Luft als [_topGap] dazu.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    required this.slivers,
    super.key,
    this.controller,
    this.floatingAction,
  });

  final List<Widget> slivers;
  final ScrollController? controller;
  final Widget? floatingAction;

  static const double _topGap = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.bg,
      floatingActionButton: floatingAction,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: _topGap)),
            ...slivers,
            // Die Tab-Leiste darf den letzten Eintrag nicht anschneiden.
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

/// Rückt einen Inhalt auf den seitlichen Bildschirmrand ein (18 px).
class ScreenPadding extends StatelessWidget {
  const ScreenPadding({required this.child, super.key, this.vertical = 0});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: vertical,
      ),
      child: child,
    );
  }
}

/// Dasselbe als Sliver, für den Einsatz in [TabScaffold].
class SliverScreenPadding extends StatelessWidget {
  const SliverScreenPadding({
    required this.sliver,
    super.key,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget sliver;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        top,
        AppSpacing.screen,
        bottom,
      ),
      sliver: sliver,
    );
  }
}

/// Ein einzelnes Widget mit Bildschirmrand als Sliver.
class SliverBox extends StatelessWidget {
  const SliverBox({
    required this.child,
    super.key,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          top,
          AppSpacing.screen,
          bottom,
        ),
        child: child,
      ),
    );
  }
}
