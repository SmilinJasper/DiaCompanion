import 'dart:math' as math;

import '../../shared/models/diabetes_input.dart';

/// Logistic regression diabetes risk predictor.
///
/// Uses pre-trained weights derived from the Pima Indians Diabetes Dataset.
/// The model predicts the probability of having diabetes given 8 clinical features.
class DiabetesPredictor {
  DiabetesPredictor._();

  // ── Pre-trained logistic regression weights ─────────────────────
  // These weights were obtained by training a logistic regression model
  // on the standardised (z-score) Pima Indians Diabetes Dataset.
  //
  // Order: pregnancies, glucose, bp, skin, insulin, bmi, dpf, age
  static const List<double> _weights = [
    0.1232,  // pregnancies
    1.1497,  // glucose            ← strongest predictor
    -0.0528, // blood pressure     ← slight negative (lower bp = higher risk)
    0.0014,  // skin thickness
    -0.0800, // insulin            ← higher insulin = lower risk (compensating)
    0.6070,  // BMI                ← strong predictor
    0.3135,  // diabetes pedigree  ← moderate predictor
    0.1509,  // age
  ];

  static const double _intercept = -0.8416;

  // ── Dataset mean/std for z-score normalisation ─────────────────
  static const List<double> _mean = [
    3.8451, 120.8945, 69.1055, 20.5367, 79.7995, 31.9926, 0.4719, 33.2408,
  ];
  static const List<double> _std = [
    3.3696, 31.9726, 19.3558, 15.9522, 115.2440, 7.8842, 0.3313, 11.7602,
  ];

  /// Predict diabetes risk from clinical input.
  static DiabetesPredictionResult predict(DiabetesInput input) {
    final features = input.toFeatures();
    final normalized = _normalize(features);

    // Compute logit: z = w·x + b
    double z = _intercept;
    for (var i = 0; i < _weights.length; i++) {
      z += _weights[i] * normalized[i];
    }

    // Sigmoid activation
    final probability = _sigmoid(z);

    // Risk tier
    final tier = probability < 0.35
        ? RiskTier.low
        : probability < 0.65
            ? RiskTier.moderate
            : RiskTier.high;

    // Feature contributions
    final contributions = <FeatureContribution>[];
    for (var i = 0; i < features.length; i++) {
      final contrib = _weights[i] * normalized[i];
      contributions.add(FeatureContribution(
        label: DiabetesInput.labels[i],
        unit: DiabetesInput.units[i],
        value: features[i],
        contribution: contrib,
        isRisk: contrib > 0.05,
      ));
    }

    // Sort by absolute contribution (most impactful first)
    contributions.sort(
        (a, b) => b.contribution.abs().compareTo(a.contribution.abs()));

    return DiabetesPredictionResult(
      input: input,
      probability: probability,
      tier: tier,
      contributions: contributions,
    );
  }

  /// Predict from a CSV string (multiple rows).
  static List<DiabetesPredictionResult> predictFromCsv(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    // Skip header if present
    int start = 0;
    if (lines[0].toLowerCase().contains('pregnancies') ||
        lines[0].toLowerCase().contains('glucose')) {
      start = 1;
    }

    final results = <DiabetesPredictionResult>[];
    for (var i = start; i < lines.length; i++) {
      try {
        final cols = lines[i].split(',');
        final input = DiabetesInput.fromCsvRow(cols);
        results.add(predict(input));
      } catch (_) {
        // Skip malformed rows
      }
    }
    return results;
  }

  // ── Internal helpers ───────────────────────────────────────────

  static List<double> _normalize(List<double> features) {
    return List.generate(features.length, (i) {
      if (_std[i] == 0) return 0.0;
      return (features[i] - _mean[i]) / _std[i];
    });
  }

  static double _sigmoid(double z) {
    return 1.0 / (1.0 + math.exp(-z));
  }
}
