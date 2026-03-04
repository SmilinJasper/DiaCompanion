/// Application-wide constants for GlucoPredict.
class AppConstants {
  AppConstants._();

  // ─── App Info ───────────────────────────────────────────────────
  static const String appName = 'DiaCompanion';
  static const String appVersion = '1.0.0';

  // ─── Layout ─────────────────────────────────────────────────────
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;

  // ─── Glucose Ranges (mg/dL) ─────────────────────────────────────
  static const double glucoseLow = 70.0;
  static const double glucoseNormal = 100.0;
  static const double glucosePreDiabetic = 125.0;
  static const double glucoseHigh = 180.0;
}
