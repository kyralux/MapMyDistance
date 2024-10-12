import 'package:flutter/material.dart';

import 'settings_service.dart';

enum DistanceUnit {
  kilometers,
  miles;

  String get short {
    switch (this) {
      case DistanceUnit.kilometers:
        return 'km';
      case DistanceUnit.miles:
        return 'mi';
    }
  }
}

class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  final SettingsService _settingsService;

  late ThemeMode _themeMode;
  late DistanceUnit _distanceUnit;

  ThemeMode get themeMode => _themeMode;
  DistanceUnit get distanceUnit => _distanceUnit;

  Future<void> loadSettings() async {
    _themeMode = await _settingsService.themeMode();
    _distanceUnit = await _settingsService.distanceUnit();

    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _settingsService.updateThemeMode(newThemeMode);
  }

  Future<void> updateDistanceUnit(DistanceUnit? newDistanceUnit) async {
    // if (newDistanceUnit == _distanceUnit) return;

    // _distanceUnit = newDistanceUnit ?? DistanceUnit.kilometers;
    // notifyListeners();
    // await _settingsService.updateDistanceUnit(newDistanceUnit!);
    if (newDistanceUnit == _distanceUnit) return;
    _distanceUnit = newDistanceUnit!;
    notifyListeners();
    await _settingsService.updateDistanceUnit(newDistanceUnit);
  }
}
