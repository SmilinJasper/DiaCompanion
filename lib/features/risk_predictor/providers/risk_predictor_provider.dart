import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/diabetes_predictor.dart';
import '../../../shared/models/diabetes_input.dart';

/// Manages state for the Diabetes Risk Predictor.
class RiskPredictorProvider extends ChangeNotifier {
  // ── Manual entry fields ─────────────────────────────────────────
  double pregnancies = 0;
  double glucose = 120;
  double bloodPressure = 70;
  double skinThickness = 20;
  double insulin = 80;
  double bmi = 25;
  double diabetesPedigree = 0.5;
  double age = 30;

  // ── Results ─────────────────────────────────────────────────────
  DiabetesPredictionResult? _result;
  DiabetesPredictionResult? get result => _result;

  List<DiabetesPredictionResult> _batchResults = [];
  List<DiabetesPredictionResult> get batchResults => _batchResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Manual Prediction ───────────────────────────────────────────
  void predictManual() {
    _errorMessage = null;
    final input = DiabetesInput(
      pregnancies: pregnancies,
      glucose: glucose,
      bloodPressure: bloodPressure,
      skinThickness: skinThickness,
      insulin: insulin,
      bmi: bmi,
      diabetesPedigree: diabetesPedigree,
      age: age,
    );
    _result = DiabetesPredictor.predict(input);
    notifyListeners();
  }

  // ── CSV Upload & Batch Prediction ───────────────────────────────
  Future<void> uploadAndPredict() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (picked == null || picked.files.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final path = picked.files.single.path;
      if (path == null) throw Exception('Could not access file');

      final content = await File(path).readAsString();
      _batchResults = DiabetesPredictor.predictFromCsv(content);

      if (_batchResults.isEmpty) {
        _errorMessage = 'No valid rows found. Expected CSV format:\n'
            'pregnancies,glucose,blood_pressure,skin_thickness,'
            'insulin,bmi,diabetes_pedigree,age';
      } else {
        // Set the first result as the primary result for display
        _result = _batchResults.first;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update individual fields ────────────────────────────────────
  void updateField(String field, double value) {
    switch (field) {
      case 'pregnancies':
        pregnancies = value;
      case 'glucose':
        glucose = value;
      case 'bloodPressure':
        bloodPressure = value;
      case 'skinThickness':
        skinThickness = value;
      case 'insulin':
        insulin = value;
      case 'bmi':
        bmi = value;
      case 'diabetesPedigree':
        diabetesPedigree = value;
      case 'age':
        age = value;
    }
    notifyListeners();
  }

  /// Clear results.
  void clearResults() {
    _result = null;
    _batchResults = [];
    _errorMessage = null;
    notifyListeners();
  }
}
