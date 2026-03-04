import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/data_center_provider.dart';
import 'glucose_chart.dart';

/// Dashboard tab — glucose trend chart + summary statistics.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<DataCenterProvider>();
    final data = provider.filteredRecords;

    if (provider.records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 72,
                color: colorScheme.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No Data Yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload a CSV or JSON file in the Upload tab to see glucose trends here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time-Range Filter Chips ──────────────────────────────
          Row(
            children: TimeRange.values.map((range) {
              final isSelected = provider.selectedRange == range;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(range.label),
                  selected: isSelected,
                  onSelected: (_) => provider.setTimeRange(range),
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Chart ───────────────────────────────────────────────
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Glucose Trend',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    child: data.isEmpty
                        ? Center(
                            child: Text(
                              'No readings in this time range',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          )
                        : GlucoseChart(
                            records: data,
                            predictions: provider.predictions,
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Prediction Summary ───────────────────────────────────────
          if (provider.predictions.isNotEmpty) ...[
            _PredictionCard(provider: provider),
            const SizedBox(height: 20),
          ],

          // ── Summary Stats ───────────────────────────────────────
          Text(
            'Statistics',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _MiniStat(
                label: 'Readings',
                value: '${data.length}',
                icon: Icons.format_list_numbered_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Average',
                value: provider.averageGlucose != null
                    ? provider.averageGlucose!.toStringAsFixed(0)
                    : '--',
                icon: Icons.analytics_outlined,
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                label: 'Min',
                value: provider.minGlucose != null
                    ? provider.minGlucose!.toStringAsFixed(0)
                    : '--',
                icon: Icons.arrow_downward_rounded,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Max',
                value: provider.maxGlucose != null
                    ? provider.maxGlucose!.toStringAsFixed(0)
                    : '--',
                icon: Icons.arrow_upward_rounded,
                color: colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat Tile ────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Prediction Summary Card ────────────────────────────────────────
class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.provider});

  final dynamic provider; // DataCenterProvider

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const forecastColor = Color(0xFFFFA726);

    final trend = provider.predictionTrend as String;
    final confidence = provider.predictionConfidence as double?;
    final predictions = provider.predictions;
    final first = predictions.isNotEmpty ? predictions.first : null;
    final last = predictions.isNotEmpty ? predictions.last : null;

    IconData trendIcon;
    switch (trend) {
      case 'Rising':
        trendIcon = Icons.trending_up_rounded;
      case 'Falling':
        trendIcon = Icons.trending_down_rounded;
      default:
        trendIcon = Icons.trending_flat_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            forecastColor.withValues(alpha: 0.15),
            forecastColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: forecastColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded,
                  color: forecastColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '3-Hour Forecast',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: forecastColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(trendIcon, color: forecastColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend: $trend',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (first != null && last != null)
                      Text(
                        '${first.predictedLevel.toStringAsFixed(0)} → '
                        '${last.predictedLevel.toStringAsFixed(0)} mg/dL',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (confidence != null)
                Column(
                  children: [
                    Text(
                      '${(confidence * 100).toInt()}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: forecastColor,
                      ),
                    ),
                    Text(
                      'confidence',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
