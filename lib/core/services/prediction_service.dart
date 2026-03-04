import 'dart:math';

import '../../shared/models/glucose_prediction.dart';
import '../../shared/models/glucose_record.dart';

/// Glucose prediction engine using weighted linear regression.
///
/// Forecasts the next 3 hours (12 points at 15-minute intervals) based on
/// recent historical readings, weighting newer data more heavily.
class PredictionService {
  PredictionService._();

  /// Number of predicted data points (every 15 min for 3 hours).
  static const int _forecastPoints = 12;

  /// Interval between forecast points.
  static const Duration _forecastInterval = Duration(minutes: 15);

  /// Maximum lookback window for regression input.
  static const Duration _lookbackWindow = Duration(hours: 24);

  /// Physiological bounds for glucose (mg/dL).
  static const double _minGlucose = 30;
  static const double _maxGlucose = 500;

  /// Generate glucose predictions from historical records.
  ///
  /// Returns an empty list if fewer than 3 data points are available.
  static List<GlucosePrediction> predict(List<GlucoseRecord> records) {
    if (records.length < 3) return [];

    // Sort ascending by timestamp
    final sorted = List<GlucoseRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Use only the most recent lookback window
    final cutoff = sorted.last.timestamp.subtract(_lookbackWindow);
    final recent = sorted.where((r) => r.timestamp.isAfter(cutoff)).toList();
    if (recent.length < 3) return [];

    // ── Convert to numeric features ────────────────────────────
    // x = minutes since the first reading in the window
    final originTime = recent.first.timestamp;
    final xs = <double>[];
    final ys = <double>[];
    final weights = <double>[];

    final totalSpanMinutes =
        recent.last.timestamp.difference(originTime).inMinutes.toDouble();

    for (var i = 0; i < recent.length; i++) {
      final minutesFromOrigin =
          recent[i].timestamp.difference(originTime).inMinutes.toDouble();
      xs.add(minutesFromOrigin);
      ys.add(recent[i].glucoseLevel);

      // Exponential weight: newer data gets more influence
      // Normalise position to [0, 1] then apply exp(2 * pos)
      final normPos =
          totalSpanMinutes > 0 ? minutesFromOrigin / totalSpanMinutes : 1.0;
      weights.add(exp(2.0 * normPos));
    }

    // ── Weighted linear regression: y = slope * x + intercept ──
    final result = _weightedLinearRegression(xs, ys, weights);
    final slope = result.slope;
    final intercept = result.intercept;
    final rSquared = result.rSquared;

    // ── Confidence: combines R² with data density ──────────────
    final dataDensity =
        (recent.length / (totalSpanMinutes / 15)).clamp(0.0, 1.0);
    final baseConfidence = (rSquared * 0.6 + dataDensity * 0.4).clamp(0.0, 1.0);

    // ── Generate forecast points ───────────────────────────────
    final lastTime = recent.last.timestamp;
    final lastMinutes = xs.last;
    final predictions = <GlucosePrediction>[];

    for (var i = 1; i <= _forecastPoints; i++) {
      final forecastMinutes =
          lastMinutes + (_forecastInterval.inMinutes * i).toDouble();
      final forecastTime = lastTime.add(_forecastInterval * i);

      // Raw prediction
      var predicted = slope * forecastMinutes + intercept;

      // Clamp to physiological bounds
      predicted = predicted.clamp(_minGlucose, _maxGlucose);

      // Confidence decays the further out we predict
      final decayFactor = 1.0 - (i / (_forecastPoints + 2)) * 0.5;
      final confidence = (baseConfidence * decayFactor).clamp(0.0, 1.0);

      predictions.add(GlucosePrediction(
        timestamp: forecastTime,
        predictedLevel: predicted,
        confidence: confidence,
      ));
    }

    return predictions;
  }

  // ─── Weighted Linear Regression ─────────────────────────────────

  static _RegressionResult _weightedLinearRegression(
    List<double> xs,
    List<double> ys,
    List<double> weights,
  ) {
    final n = xs.length;
    double sumW = 0, sumWx = 0, sumWy = 0, sumWxx = 0, sumWxy = 0;

    for (var i = 0; i < n; i++) {
      final w = weights[i];
      sumW += w;
      sumWx += w * xs[i];
      sumWy += w * ys[i];
      sumWxx += w * xs[i] * xs[i];
      sumWxy += w * xs[i] * ys[i];
    }

    final denom = sumW * sumWxx - sumWx * sumWx;
    if (denom.abs() < 1e-10) {
      // Degenerate case — flat line at the mean
      final meanY = sumWy / sumW;
      return _RegressionResult(slope: 0, intercept: meanY, rSquared: 0);
    }

    final slope = (sumW * sumWxy - sumWx * sumWy) / denom;
    final intercept = (sumWy - slope * sumWx) / sumW;

    // ── R² (coefficient of determination) ──────────────────────
    final meanY = sumWy / sumW;
    double ssTot = 0, ssRes = 0;
    for (var i = 0; i < n; i++) {
      final predicted = slope * xs[i] + intercept;
      ssRes += weights[i] * (ys[i] - predicted) * (ys[i] - predicted);
      ssTot += weights[i] * (ys[i] - meanY) * (ys[i] - meanY);
    }

    final rSquared = ssTot > 0 ? (1.0 - ssRes / ssTot).clamp(0.0, 1.0) : 0.0;

    return _RegressionResult(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
    );
  }
}

/// Internal result of a weighted linear regression.
class _RegressionResult {
  final double slope;
  final double intercept;
  final double rSquared;

  const _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });
}
