import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data_center/presentation/pages/data_center_page.dart';
import '../../../data_center/providers/data_center_provider.dart';
import '../../../diabot/presentation/pages/diabot_page.dart';
import '../../../risk_predictor/presentation/pages/risk_predictor_page.dart';
import '../../providers/home_provider.dart';
import '../widgets/log_glucose_sheet.dart';

/// Home page — the main dashboard screen of GlucoPredict.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<HomeProvider>();
    final dataProvider = context.watch<DataCenterProvider>();

    // ── Compute live stats ─────────────────────────────────
    final records = dataProvider.records;
    final lastReading = records.isNotEmpty
        ? '${records.last.glucoseLevel.toStringAsFixed(0)} mg/dL'
        : '-- mg/dL';

    final trend = dataProvider.predictionTrend;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final readingsToday =
        records.where((r) => r.timestamp.isAfter(todayStart)).length;

    // 7-day average
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final last7d = records.where((r) => r.timestamp.isAfter(sevenDaysAgo));
    final avg7d = last7d.isNotEmpty
        ? (last7d.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
            last7d.length)
        : null;
    final avg7dStr =
        avg7d != null ? '${avg7d.toStringAsFixed(0)} mg/dL' : '-- mg/dL';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DiaCompanion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DiaBotPage(),
            ),
          );
        },
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text('Ask DiaBot'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting Banner ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.greeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor your glucose levels and stay healthy.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Stats Section ─────────────────────────────
              Text(
                'Quick Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.water_drop_outlined,
                      label: 'Last Reading',
                      value: lastReading,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Trend',
                      value: trend,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Readings Today',
                      value: '$readingsToday',
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assessment_outlined,
                      label: 'Avg (7d)',
                      value: avg7dStr,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Action Buttons ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => LogGlucoseSheet.show(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Log Glucose Reading'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataCenterPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storage_rounded),
                  label: const Text('Data Center'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataCenterPage(initialTab: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_graph_rounded),
                  label: const Text('View Predictions'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiskPredictorPage(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                  icon: const Icon(Icons.science_rounded),
                  label: const Text('Predict Diabetes Risk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private Stat Card Widget ──────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
