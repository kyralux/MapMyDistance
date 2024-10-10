import 'package:flutter/material.dart';
import 'package:mapgoal/src/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<ThemeMode> themeMode() async => ThemeMode.system;

  Future<void> updateThemeMode(ThemeMode theme) async {}

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


// meine großen probleme beim programmieren
/// neues lernen
/// wohin mir allem? :o zb jetzt wo place ich die shared preferences?
/// 