import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/file_parser_service.dart';
import '../../../core/services/prediction_service.dart';
import '../../../shared/models/glucose_prediction.dart';
import '../../../shared/models/glucose_record.dart';

/// Manages state for the Data Center feature.
class DataCenterProvider extends ChangeNotifier {
  // ─── State ──────────────────────────────────────────────────────
  List<GlucoseRecord> _records = [];
  List<GlucoseRecord> get records => _records;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FileParseResult? _lastResult;
  FileParseResult? get lastResult => _lastResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Predicted glucose values (next 3 hours).
  List<GlucosePrediction> _predictions = [];
  List<GlucosePrediction> get predictions => _predictions;

  /// Selected time-range filter for the chart.
  TimeRange _selectedRange = TimeRange.week;
  TimeRange get selectedRange => _selectedRange;

  // ─── Initialisation ────────────────────────────────────────────

  DataCenterProvider() {
    loadRecords();
  }

  // ─── File Upload ───────────────────────────────────────────────

  Future<void> uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      _isLoading = true;
      _errorMessage = null;
      _lastResult = null;
      notifyListeners();

      final filePath = result.files.single.path;
      if (filePath == null) {
        _errorMessage = 'Could not access the selected file.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final file = File(filePath);
      final parseResult = FileParserService.parseFile(file);

      if (parseResult.records.isNotEmpty) {
        await DatabaseService.addRecords(parseResult.records);
      }

      _lastResult = parseResult;
      _isLoading = false;
      await loadRecords();
    } catch (e) {
      _errorMessage = 'Upload failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Data Loading ──────────────────────────────────────────────

  Future<void> loadRecords() async {
    _records = DatabaseService.getAllRecords();
    _generatePredictions();
    notifyListeners();
  }

  // ─── Chart Filtering ──────────────────────────────────────────

  void setTimeRange(TimeRange range) {
    _selectedRange = range;
    _generatePredictions();
    notifyListeners();
  }

  // ─── Predictions ───────────────────────────────────────────────

  void _generatePredictions() {
    final data = filteredRecords;
    _predictions = PredictionService.predict(data);
  }

  /// Human-readable prediction trend.
  String get predictionTrend {
    if (_predictions.isEmpty) return 'No prediction';
    final first = _predictions.first.predictedLevel;
    final last = _predictions.last.predictedLevel;
    final diff = last - first;
    if (diff > 5) return 'Rising';
    if (diff < -5) return 'Falling';
    return 'Stable';
  }

  /// Average confidence of current predictions.
  double? get predictionConfidence {
    if (_predictions.isEmpty) return null;
    return _predictions.map((p) => p.confidence).reduce((a, b) => a + b) /
        _predictions.length;
  }

  List<GlucoseRecord> get filteredRecords {
    if (_records.isEmpty) return [];

    final now = DateTime.now();
    late DateTime from;

    switch (_selectedRange) {
      case TimeRange.day:
        from = now.subtract(const Duration(hours: 24));
      case TimeRange.week:
        from = now.subtract(const Duration(days: 7));
      case TimeRange.month:
        from = now.subtract(const Duration(days: 30));
      case TimeRange.all:
        return _records;
    }

    return _records
        .where((r) => r.timestamp.isAfter(from))
        .toList();
  }

  // ─── Stats ─────────────────────────────────────────────────────

  double? get averageGlucose {
    final data = filteredRecords;
    if (data.isEmpty) return null;
    return data.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
        data.length;
  }

  double? get minGlucose {
    final data = filteredRecords;
    if (data.isEmpty) return null;
    return data.map((r) => r.glucoseLevel).reduce((a, b) => a < b ? a : b);
  }

  double? get maxGlucose {
    final data = filteredRecords;
    if (data.isEmpty) return null;
    return data.map((r) => r.glucoseLevel).reduce((a, b) => a > b ? a : b);
  }

  // ─── Deletion ──────────────────────────────────────────────────

  Future<void> deleteRecord(int key) async {
    await DatabaseService.deleteRecord(key);
    await loadRecords();
  }

  Future<void> clearAllData() async {
    await DatabaseService.clearAll();
    _lastResult = null;
    _errorMessage = null;
    await loadRecords();
  }

  void clearUploadResult() {
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Time range options for chart filtering.
enum TimeRange {
  day('24h'),
  week('7d'),
  month('30d'),
  all('All');

  const TimeRange(this.label);
  final String label;
}
