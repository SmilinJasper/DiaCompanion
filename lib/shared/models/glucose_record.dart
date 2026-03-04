import 'package:hive/hive.dart';

part 'glucose_record.g.dart';

/// A single blood glucose reading with optional nutritional context.
@HiveType(typeId: 0)
class GlucoseRecord extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  double glucoseLevel; // mg/dL

  @HiveField(2)
  double? carbsIntake; // grams

  @HiveField(3)
  double? insulinDose; // units

  GlucoseRecord({
    required this.timestamp,
    required this.glucoseLevel,
    this.carbsIntake,
    this.insulinDose,
  });

  /// Creates a record from a parsed map (CSV row or JSON object).
  factory GlucoseRecord.fromMap(Map<String, dynamic> map) {
    return GlucoseRecord(
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp'] as DateTime
          : DateTime.parse(map['timestamp'] as String),
      glucoseLevel: (map['glucose_level'] as num).toDouble(),
      carbsIntake: map['carbs_intake'] != null
          ? (map['carbs_intake'] as num).toDouble()
          : null,
      insulinDose: map['insulin_dose'] != null
          ? (map['insulin_dose'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'glucose_level': glucoseLevel,
      'carbs_intake': carbsIntake,
      'insulin_dose': insulinDose,
    };
  }

  @override
  String toString() =>
      'GlucoseRecord(${timestamp.toIso8601String()}, $glucoseLevel mg/dL)';
}
