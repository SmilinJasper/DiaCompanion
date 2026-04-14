import 'package:flutter_test/flutter_test.dart';
import 'package:gluco_predict/core/services/prediction_service.dart';
import 'package:gluco_predict/shared/models/glucose_record.dart';

void main() {
  test('Test prediction service with simulated historical data', () {
    final now = DateTime.now();
    final records = [
      GlucoseRecord(timestamp: now.subtract(Duration(minutes: 60)), glucoseLevel: 100),
      GlucoseRecord(timestamp: now.subtract(Duration(minutes: 45)), glucoseLevel: 105),
      GlucoseRecord(timestamp: now.subtract(Duration(minutes: 30)), glucoseLevel: 110),
      GlucoseRecord(timestamp: now.subtract(Duration(minutes: 15)), glucoseLevel: 115),
      GlucoseRecord(timestamp: now, glucoseLevel: 120),
    ];

    final predictions = PredictionService.predict(records);
    
    print('Input records: ${records.length}');
    print('Predictions generated: ${predictions.length}');
    if (predictions.isNotEmpty) {
      print('First prediction: ${predictions.first.predictedLevel}');
      print('Last prediction: ${predictions.last.predictedLevel}');
    }
    
    expect(predictions, isNotEmpty);
  });
}

