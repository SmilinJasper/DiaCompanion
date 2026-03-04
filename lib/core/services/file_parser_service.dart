import 'dart:convert';
import 'dart:io';

import '../../shared/models/glucose_record.dart';

/// Result of parsing a file — contains successfully parsed records and errors.
class FileParseResult {
  final List<GlucoseRecord> records;
  final List<String> errors;

  const FileParseResult({required this.records, required this.errors});

  int get successCount => records.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
}

/// Parses CSV and JSON files containing blood glucose data.
class FileParserService {
  FileParserService._();

  static const _requiredField = 'glucose_level';
  static const _timestampField = 'timestamp';

  /// Parse a file (CSV or JSON) and return validated [GlucoseRecord]s.
  static FileParseResult parseFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      case 'csv':
        return _parseCsv(file);
      case 'json':
        return _parseJson(file);
      default:
        return const FileParseResult(
          records: [],
          errors: ['Unsupported file format. Please use CSV or JSON.'],
        );
    }
  }

  // ─── CSV ───────────────────────────────────────────────────────

  static FileParseResult _parseCsv(File file) {
    final records = <GlucoseRecord>[];
    final errors = <String>[];

    final lines = file.readAsLinesSync();
    if (lines.isEmpty) {
      return const FileParseResult(
        records: [],
        errors: ['CSV file is empty.'],
      );
    }

    // Parse header row
    final headers = lines.first
        .split(',')
        .map((h) => h.trim().toLowerCase().replaceAll(RegExp(r'[\r\n]'), ''))
        .toList();

    if (!headers.contains(_requiredField)) {
      return FileParseResult(
        records: [],
        errors: [
          'CSV must contain a "$_requiredField" column. '
              'Found columns: ${headers.join(", ")}'
        ],
      );
    }

    // Parse data rows
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final values = _parseCsvLine(line);
        if (values.length != headers.length) {
          errors.add('Row ${i + 1}: column count mismatch '
              '(expected ${headers.length}, got ${values.length})');
          continue;
        }

        final map = <String, dynamic>{};
        for (var j = 0; j < headers.length; j++) {
          map[headers[j]] = values[j].trim();
        }

        final record = _mapToRecord(map, i + 1);
        if (record != null) {
          records.add(record);
        } else {
          errors.add('Row ${i + 1}: invalid data — check values');
        }
      } catch (e) {
        errors.add('Row ${i + 1}: $e');
      }
    }

    return FileParseResult(records: records, errors: errors);
  }

  /// Simple CSV line parser that handles quoted fields.
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  // ─── JSON ──────────────────────────────────────────────────────

  static FileParseResult _parseJson(File file) {
    final records = <GlucoseRecord>[];
    final errors = <String>[];

    try {
      final content = file.readAsStringSync();
      final decoded = json.decode(content);

      List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        items = decoded['data'] as List<dynamic>;
      } else {
        return const FileParseResult(
          records: [],
          errors: [
            'JSON must be an array or an object with a "data" array field.'
          ],
        );
      }

      for (var i = 0; i < items.length; i++) {
        try {
          if (items[i] is! Map<String, dynamic>) {
            errors.add('Item ${i + 1}: not a valid JSON object');
            continue;
          }
          final map = items[i] as Map<String, dynamic>;

          if (!map.containsKey(_requiredField)) {
            errors.add('Item ${i + 1}: missing "$_requiredField" field');
            continue;
          }

          final record = _mapToRecord(map, i + 1);
          if (record != null) {
            records.add(record);
          } else {
            errors.add('Item ${i + 1}: invalid data — check values');
          }
        } catch (e) {
          errors.add('Item ${i + 1}: $e');
        }
      }
    } on FormatException catch (e) {
      errors.add('Invalid JSON: ${e.message}');
    } catch (e) {
      errors.add('Error reading JSON file: $e');
    }

    return FileParseResult(records: records, errors: errors);
  }

  // ─── Shared Validation ─────────────────────────────────────────

  /// Convert a map of string values into a [GlucoseRecord], or null if invalid.
  static GlucoseRecord? _mapToRecord(Map<String, dynamic> map, int rowIndex) {
    try {
      // Timestamp — required
      DateTime timestamp;
      if (map.containsKey(_timestampField) &&
          map[_timestampField] != null &&
          map[_timestampField].toString().isNotEmpty) {
        timestamp = DateTime.parse(map[_timestampField].toString());
      } else {
        timestamp = DateTime.now();
      }

      // Glucose level — required, must be > 0
      final glucoseStr = map[_requiredField].toString().trim();
      final glucose = double.tryParse(glucoseStr);
      if (glucose == null || glucose <= 0) return null;

      // Carbs intake — optional, must be >= 0
      double? carbs;
      if (map.containsKey('carbs_intake') &&
          map['carbs_intake'] != null &&
          map['carbs_intake'].toString().trim().isNotEmpty) {
        carbs = double.tryParse(map['carbs_intake'].toString().trim());
        if (carbs != null && carbs < 0) carbs = null;
      }

      // Insulin dose — optional, must be >= 0
      double? insulin;
      if (map.containsKey('insulin_dose') &&
          map['insulin_dose'] != null &&
          map['insulin_dose'].toString().trim().isNotEmpty) {
        insulin = double.tryParse(map['insulin_dose'].toString().trim());
        if (insulin != null && insulin < 0) insulin = null;
      }

      return GlucoseRecord(
        timestamp: timestamp,
        glucoseLevel: glucose,
        carbsIntake: carbs,
        insulinDose: insulin,
      );
    } catch (_) {
      return null;
    }
  }
}
