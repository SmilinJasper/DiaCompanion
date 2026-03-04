import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/diabetes_input.dart';
import '../../providers/risk_predictor_provider.dart';
import '../widgets/risk_gauge.dart';

/// Diabetes Risk Predictor — enter clinical data or upload CSV to predict risk.
class RiskPredictorPage extends StatelessWidget {
  const RiskPredictorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<RiskPredictorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabetes Risk Predictor'),
        actions: [
          if (provider.result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Clear results',
              onPressed: provider.clearResults,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Result Card (if available) ──────────────────────────
            if (provider.result != null) ...[
              _buildResultCard(context, provider),
              const SizedBox(height: 20),
            ],

            // ── CSV Upload Card ─────────────────────────────────────
            _buildUploadCard(context, provider),
            const SizedBox(height: 16),

            // ── Divider ─────────────────────────────────────────────
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR ENTER MANUALLY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),

            // ── Manual Entry Form ───────────────────────────────────
            _buildSlider(context, provider, 'pregnancies', 'Pregnancies',
                'count', 0, 17, 1, provider.pregnancies),
            _buildSlider(context, provider, 'glucose', 'Glucose (OGTT)',
                'mg/dL', 0, 200, 1, provider.glucose),
            _buildSlider(context, provider, 'bloodPressure', 'Blood Pressure',
                'mm Hg', 0, 140, 1, provider.bloodPressure),
            _buildSlider(context, provider, 'skinThickness',
                'Skin Thickness', 'mm', 0, 99, 1, provider.skinThickness),
            _buildSlider(context, provider, 'insulin', 'Insulin (2-hr)',
                'µU/mL', 0, 846, 1, provider.insulin),
            _buildSlider(context, provider, 'bmi', 'BMI', 'kg/m²', 0, 70,
                0.1, provider.bmi),
            _buildSlider(context, provider, 'diabetesPedigree',
                'Diabetes Pedigree', 'score', 0, 2.5, 0.01,
                provider.diabetesPedigree),
            _buildSlider(context, provider, 'age', 'Age', 'years', 21, 81,
                1, provider.age),

            const SizedBox(height: 16),

            // ── Predict Button ──────────────────────────────────────
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: provider.predictManual,
                icon: const Icon(Icons.science_rounded),
                label: const Text('Predict Diabetes Risk'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Medical Disclaimer ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tool is for informational purposes only. '
                      'It does not replace professional medical diagnosis. '
                      'Please consult your healthcare provider.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Batch Results (if CSV uploaded) ─────────────────────
            if (provider.batchResults.length > 1) ...[
              Text(
                'Batch Results (${provider.batchResults.length} rows)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...provider.batchResults.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final tierColor = _tierColor(r.tier);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tierColor.withValues(alpha: 0.15),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: tierColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(r.tier.label),
                    subtitle: Text(
                      'Glucose: ${r.input.glucose.toStringAsFixed(0)}, '
                      'BMI: ${r.input.bmi.toStringAsFixed(1)}, '
                      'Age: ${r.input.age.toStringAsFixed(0)}',
                    ),
                    trailing: Text(
                      '${(r.probability * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // Show detail for this row
                      provider.clearResults();
                      provider.pregnancies = r.input.pregnancies;
                      provider.glucose = r.input.glucose;
                      provider.bloodPressure = r.input.bloodPressure;
                      provider.skinThickness = r.input.skinThickness;
                      provider.insulin = r.input.insulin;
                      provider.bmi = r.input.bmi;
                      provider.diabetesPedigree = r.input.diabetesPedigree;
                      provider.age = r.input.age;
                      provider.predictManual();
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ── Result Card ──────────────────────────────────────────────────

  Widget _buildResultCard(BuildContext context, RiskPredictorProvider prov) {
    final theme = Theme.of(context);
    final result = prov.result!;
    final tierColor = _tierColor(result.tier);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RiskGauge(
              probability: result.probability,
              tierLabel: result.tier.label,
              tierColor: tierColor,
            ),
            const SizedBox(height: 8),
            Text(
              result.tier.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 28),
            Text(
              'Risk Factor Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...result.contributions.map((c) => _buildContributionBar(
                  context, c, tierColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionBar(
      BuildContext context, FeatureContribution c, Color tierColor) {
    final theme = Theme.of(context);
    final isPositive = c.contribution > 0;
    final barColor = isPositive
        ? Colors.red.shade400
        : Colors.green.shade400;
    final barWidth = (c.contribution.abs() / 2.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              c.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: barWidth,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              '${c.value.toStringAsFixed(c.unit == 'score' ? 2 : 0)} ${c.unit}',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload Card ──────────────────────────────────────────────────

  Widget _buildUploadCard(
      BuildContext context, RiskPredictorProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: provider.isLoading ? null : provider.uploadAndPredict,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.upload_file_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload CSV for Prediction',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Columns: pregnancies, glucose, blood_pressure,\n'
              'skin_thickness, insulin, bmi, diabetes_pedigree, age',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            if (provider.isLoading) ...[
              const SizedBox(height: 12),
              const CircularProgressIndicator(strokeWidth: 2),
            ],
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Slider Field ─────────────────────────────────────────────────

  Widget _buildSlider(
    BuildContext context,
    RiskPredictorProvider provider,
    String field,
    String label,
    String unit,
    double min,
    double max,
    double step,
    double currentValue,
  ) {
    final theme = Theme.of(context);
    final divisions = ((max - min) / step).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${step < 1 ? currentValue.toStringAsFixed(step < 0.1 ? 2 : 1) : currentValue.toStringAsFixed(0)} $unit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : 1,
            onChanged: (v) => provider.updateField(field, v),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  static Color _tierColor(RiskTier tier) {
    switch (tier) {
      case RiskTier.low:
        return Colors.green.shade600;
      case RiskTier.moderate:
        return Colors.orange.shade700;
      case RiskTier.high:
        return Colors.red.shade600;
    }
  }
}
