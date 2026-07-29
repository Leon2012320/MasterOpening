import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Wie stark eine Fläche vom Grund abhebt.
///
/// Nocturne erzeugt Erhebung nicht über Helligkeit, sondern über einen
/// 1-px-Haarrand plus — bei stärkerer Erhebung — einen weichen Schatten
/// darunter.
enum AppElevation { none, sm, md, lg }

/// Die Standardfläche der App: Hintergrund `surface`, Haarrand, weiche Ecken.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.margin,
    this.radius = AppRadius.xl,
    this.elevation = AppElevation.sm,
    this.onTap,
    this.color,
    this.clipContent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final AppElevation elevation;
  final VoidCallback? onTap;
  final Color? color;

  /// Schneidet den Inhalt an den Ecken ab — nötig, wenn ein Brett oder Bild
  /// bündig bis an den Kartenrand läuft.
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderRadius = BorderRadius.circular(radius);

    final shadows = switch (elevation) {
      AppElevation.none => const <BoxShadow>[],
      AppElevation.sm => tokens.shadowSm,
      AppElevation.md => tokens.shadowMd,
      AppElevation.lg => tokens.shadowLg,
    };

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashFactory: NoSplash.splashFactory,
        highlightColor: tokens.textAlpha(0.05),
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
      clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
