import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/glucose_prediction.dart';
import '../../../../shared/models/glucose_record.dart';

/// Interactive line chart showing glucose level trends over time,
/// with an optional dotted forecast line for predicted values.
class GlucoseChart extends StatelessWidget {
  const GlucoseChart({
    super.key,
    required this.records,
    this.predictions,
  });

  final List<GlucoseRecord> records;
  final List<GlucosePrediction>? predictions;

  // Glucose reference thresholds (mg/dL)
  static const double _lowThreshold = 70;
  static const double _normalThreshold = 100;
  static const double _highThreshold = 180;

  // Colors
  static const Color _forecastColor = Color(0xFFFFA726); // Orange/amber

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (records.isEmpty) return const SizedBox.shrink();

    final sorted = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final hasPredictions =
        predictions != null && predictions!.isNotEmpty;

    // ── Build a unified timestamp list for the X axis ──────────
    // All timestamps in order: historical + predictions
    final allTimestamps = <DateTime>[
      ...sorted.map((r) => r.timestamp),
      if (hasPredictions) ...predictions!.map((p) => p.timestamp),
    ];

    // ── Historical spots ──────────────────────────────────────
    final histSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      histSpots.add(FlSpot(i.toDouble(), sorted[i].glucoseLevel));
    }

    // ── Forecast spots (start from the last historical point) ──
    final forecastSpots = <FlSpot>[];
    if (hasPredictions) {
      // Connect forecast to the last historical point
      final bridgeIdx = sorted.length - 1;
      forecastSpots
          .add(FlSpot(bridgeIdx.toDouble(), sorted.last.glucoseLevel));

      for (var i = 0; i < predictions!.length; i++) {
        final xIdx = sorted.length + i;
        forecastSpots
            .add(FlSpot(xIdx.toDouble(), predictions![i].predictedLevel));
      }
    }

    // ── Y-axis bounds ─────────────────────────────────────────
    final allYValues = <double>[
      ...sorted.map((r) => r.glucoseLevel),
      if (hasPredictions) ...predictions!.map((p) => p.predictedLevel),
    ];
    final minY =
        (allYValues.reduce((a, b) => a < b ? a : b) - 20).clamp(0.0, double.infinity);
    final maxY = allYValues.reduce((a, b) => a > b ? a : b) + 20;

    final totalPoints = allTimestamps.length;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // Y-axis
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: 40,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          // X-axis
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _xInterval(totalPoints),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= allTimestamps.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(allTimestamps[idx], totalPoints),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),

        // ── Reference Lines ───────────────────────────────────
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            _refLine(_lowThreshold, Colors.orange.shade400, 'Low'),
            _refLine(_normalThreshold, Colors.green.shade400, 'Normal'),
            _refLine(_highThreshold, Colors.red.shade400, 'High'),
          ],
          // Vertical line separating history from forecast
          verticalLines: hasPredictions
              ? [
                  VerticalLine(
                    x: (sorted.length - 1).toDouble(),
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      labelResolver: (_) => 'Now',
                    ),
                  ),
                ]
              : [],
        ),

        // ── Line data ─────────────────────────────────────────
        lineBarsData: [
          // Historical data — solid teal line
          LineChartBarData(
            spots: histSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: colorScheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: sorted.length <= 60,
              getDotPainter: (spot, _, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: colorScheme.primary,
                strokeWidth: 1.5,
                strokeColor: colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.25),
                  colorScheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Forecast data — dashed orange line
          if (hasPredictions && forecastSpots.isNotEmpty)
            LineChartBarData(
              spots: forecastSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: _forecastColor,
              barWidth: 2.5,
              dashArray: [8, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, bar, index) {
                  // Skip the bridge point (index 0)
                  if (index == 0) {
                    return FlDotCirclePainter(
                      radius: 0,
                      color: Colors.transparent,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: _forecastColor,
                    strokeWidth: 1.5,
                    strokeColor: colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _forecastColor.withValues(alpha: 0.12),
                    _forecastColor.withValues(alpha: 0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
        ],

        // ── Touch Tooltips ────────────────────────────────────
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                colorScheme.inverseSurface.withValues(alpha: 0.9),
            tooltipRoundedRadius: 10,
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.toInt();
              final isHistorical = idx < sorted.length;

              DateTime? time;
              String label;
              Color textColor;

              if (isHistorical) {
                time = sorted[idx].timestamp;
                label = '${spot.y.toStringAsFixed(0)} mg/dL';
                textColor = colorScheme.onInverseSurface;
              } else {
                final predIdx = idx - sorted.length;
                if (predictions != null && predIdx < predictions!.length) {
                  time = predictions![predIdx].timestamp;
                  final conf =
                      (predictions![predIdx].confidence * 100).toInt();
                  label = '${spot.y.toStringAsFixed(0)} mg/dL (predicted)\n'
                      'Confidence: $conf%';
                } else {
                  label = '${spot.y.toStringAsFixed(0)} mg/dL';
                }
                textColor = _forecastColor;
              }

              final dateStr = time != null
                  ? DateFormat('MMM d, h:mm a').format(time)
                  : '';

              return LineTooltipItem(
                '$label\n',
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: dateStr,
                    style: TextStyle(
                      color:
                          colorScheme.onInverseSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  static HorizontalLine _refLine(double y, Color color, String label) {
    return HorizontalLine(
      y: y,
      color: color.withValues(alpha: 0.5),
      strokeWidth: 1,
      dashArray: [6, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        labelResolver: (_) => '$label ($y)',
      ),
    );
  }

  static double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 30) return 5;
    if (count <= 90) return 15;
    return (count / 6).roundToDouble();
  }

  static String _formatDate(DateTime dt, int totalPoints) {
    if (totalPoints <= 7) return DateFormat('M/d\nha').format(dt);
    return DateFormat('M/d').format(dt);
  }
}
