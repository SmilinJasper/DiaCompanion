import 'package:flutter/foundation.dart';

/// Provider for the Home feature.
///
/// Manages state for the home screen of GlucoPredict.
class HomeProvider extends ChangeNotifier {
  // ─── Greeting ───────────────────────────────────────────────────
  String _greeting = 'Welcome to DiaCompanion';

  String get greeting => _greeting;

  void updateGreeting(String value) {
    _greeting = value;
    notifyListeners();
  }

  // ─── Selected Tab (for future bottom nav) ───────────────────────
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
