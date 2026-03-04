/// Clinical health data for diabetes risk prediction.
///
/// Based on the Pima Indians Diabetes Dataset format.
class DiabetesInput {
  final double pregnancies;
  final double glucose;
  final double bloodPressure;
  final double skinThickness;
  final double insulin;
  final double bmi;
  final double diabetesPedigree;
  final double age;

  const DiabetesInput({
    required this.pregnancies,
    required this.glucose,
    required this.bloodPressure,
    required this.skinThickness,
    required this.insulin,
    required this.bmi,
    required this.diabetesPedigree,
    required this.age,
  });

  /// Parse from a CSV row: pregnancies,glucose,bp,skin,insulin,bmi,dpf,age
  factory DiabetesInput.fromCsvRow(List<String> cols) {
    if (cols.length < 8) {
      throw FormatException(
        'Expected 8 columns, got ${cols.length}',
      );
    }
    return DiabetesInput(
      pregnancies: double.parse(cols[0].trim()),
      glucose: double.parse(cols[1].trim()),
      bloodPressure: double.parse(cols[2].trim()),
      skinThickness: double.parse(cols[3].trim()),
      insulin: double.parse(cols[4].trim()),
      bmi: double.parse(cols[5].trim()),
      diabetesPedigree: double.parse(cols[6].trim()),
      age: double.parse(cols[7].trim()),
    );
  }

  /// Returns the 8 feature values as a list.
  List<double> toFeatures() => [
        pregnancies,
        glucose,
        bloodPressure,
        skinThickness,
        insulin,
        bmi,
        diabetesPedigree,
        age,
      ];

  /// Feature labels for display.
  static const labels = [
    'Pregnancies',
    'Glucose',
    'Blood Pressure',
    'Skin Thickness',
    'Insulin',
    'BMI',
    'Diabetes Pedigree',
    'Age',
  ];

  /// Units for each feature.
  static const units = [
    'count',
    'mg/dL',
    'mm Hg',
    'mm',
    'µU/mL',
    'kg/m²',
    'score',
    'years',
  ];
}

/// Risk tier from the prediction.
enum RiskTier {
  low('Low Risk', 'Your risk is within the normal range.'),
  moderate('Moderate Risk', 'Some risk factors present. Consider lifestyle changes.'),
  high('High Risk', 'Multiple risk factors detected. Please consult a doctor.');

  const RiskTier(this.label, this.description);
  final String label;
  final String description;
}

/// Result of a diabetes risk prediction.
class DiabetesPredictionResult {
  final DiabetesInput input;
  final double probability;
  final RiskTier tier;
  final List<FeatureContribution> contributions;

  const DiabetesPredictionResult({
    required this.input,
    required this.probability,
    required this.tier,
    required this.contributions,
  });
}

/// How much each feature contributed to the risk score.
class FeatureContribution {
  final String label;
  final String unit;
  final double value;
  final double contribution; // -1 to 1 scale
  final bool isRisk;

  const FeatureContribution({
    required this.label,
    required this.unit,
    required this.value,
    required this.contribution,
    required this.isRisk,
  });
}
