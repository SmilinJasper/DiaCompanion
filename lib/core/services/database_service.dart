import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/glucose_record.dart';

/// Singleton service for Hive database operations on glucose records.
class DatabaseService {
  DatabaseService._();

  static const String _boxName = 'glucose_records';
  static Box<GlucoseRecord>? _box;

  /// Initialise Hive and open the glucose-records box.
  /// Must be called before [runApp].
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GlucoseRecordAdapter());
    _box = await Hive.openBox<GlucoseRecord>(_boxName);
  }

  static Box<GlucoseRecord> get box {
    assert(_box != null, 'DatabaseService.init() must be called first');
    return _box!;
  }

  // ─── CRUD ──────────────────────────────────────────────────────

  /// Add a single record and return its key.
  static Future<int> addRecord(GlucoseRecord record) async {
    return await box.add(record);
  }

  /// Add multiple records in one batch.
  static Future<List<int>> addRecords(List<GlucoseRecord> records) async {
    final keys = <int>[];
    for (final record in records) {
      final key = await box.add(record);
      keys.add(key);
    }
    return keys;
  }

  /// All records sorted by timestamp (ascending).
  static List<GlucoseRecord> getAllRecords() {
    final records = box.values.toList();
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }

  /// Records within the given date range, inclusive.
  static List<GlucoseRecord> getRecordsByDateRange(
    DateTime from,
    DateTime to,
  ) {
    return getAllRecords()
        .where((r) =>
            (r.timestamp.isAfter(from) || r.timestamp.isAtSameMomentAs(from)) &&
            (r.timestamp.isBefore(to) || r.timestamp.isAtSameMomentAs(to)))
        .toList();
  }

  /// Delete a single record by its Hive key.
  static Future<void> deleteRecord(int key) async {
    await box.delete(key);
  }

  /// Remove every record.
  static Future<void> clearAll() async {
    await box.clear();
  }

  /// Total number of stored records.
  static int get recordCount => box.length;
}
