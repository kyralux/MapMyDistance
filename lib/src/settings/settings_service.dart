import 'package:flutter/material.dart';
import 'package:mapgoal/src/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<ThemeMode> themeMode() async {
    await _initPrefs();
    final themeString = _prefs!.getString('theme_mode') ??
        ThemeMode.system.name; // Default to system theme
    return ThemeMode.values.firstWhere((e) => e.name == themeString);
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    await _initPrefs();
    await _prefs!.setString('theme_mode', theme.name);
  }

  Future<DistanceUnit> distanceUnit() async {
    await _initPrefs();
    final unitString =
        _prefs!.getString('distance_unit') ?? DistanceUnit.kilometers.name;
    return DistanceUnit.values.firstWhere((e) => e.name == unitString);
  }

  Future<void> updateDistanceUnit(DistanceUnit distanceUnit) async {
    await _initPrefs();
    await _prefs!.setString('distance_unit', distanceUnit.name);
  }
}
