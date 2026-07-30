import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Der Genauigkeitsverlauf über die letzten Einheiten.
///
/// Ohne Achsenbeschriftung und ohne Gitter: es geht um die Richtung, nicht um
/// den Einzelwert. Die Skala beginnt bei 50 %, weil darunter im Training
/// praktisch nichts vorkommt und die Kurve sonst platt am oberen Rand klebt.
class AccuracyChart extends StatelessWidget {
  const AccuracyChart({required this.sessions, super.key});

  /// Die Einheiten, neueste zuerst.
  final List<TrainingSession> sessions;

  static const _minPercent = 50.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Für die Anzeige umdrehen: die Zeit läuft nach rechts.
    final points = sessions.reversed.where((s) => s.movesTotal > 0).toList();

    if (points.length < 2) {
      return const SizedBox(height: 140);
    }

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(
          i.toDouble(),
          (points[i].movesCorrect / points[i].movesTotal * 100).clamp(
            _minPercent,
            100,
          ),
        ),
    ];

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: _minPercent,
          maxY: 100,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: tokens.accent,
              dotData: FlDotData(
                // Nur der letzte Wert bekommt einen Punkt — er ist der, auf
                // den es ankommt.
                checkToShowDot: (spot, _) => spot.x == spots.last.x,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3.5,
                      color: tokens.accent,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tokens.accent.withValues(alpha: 0.18),
                    tokens.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
