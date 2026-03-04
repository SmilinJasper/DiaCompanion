/// A single predicted glucose data point.
class GlucosePrediction {
  /// The forecasted timestamp.
  final DateTime timestamp;

  /// Predicted glucose level in mg/dL.
  final double predictedLevel;

  /// Confidence score from 0.0 (low) to 1.0 (high).
  final double confidence;

  const GlucosePrediction({
    required this.timestamp,
    required this.predictedLevel,
    required this.confidence,
  });

  @override
  String toString() =>
      'GlucosePrediction(${timestamp.toIso8601String()}, '
      '${predictedLevel.toStringAsFixed(1)} mg/dL, '
      'conf=${confidence.toStringAsFixed(2)})';
}
