import 'package:flutter/material.dart';

import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButton<ThemeMode>(
            value: controller.themeMode,
            onChanged: controller.updateThemeMode,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System Theme'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light Theme'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Theme'),
              )
            ],
          ),
          DropdownButton<DistanceUnit>(
            value: controller.distanceUnit,
            onChanged: controller.updateDistanceUnit,
            items: DistanceUnit.values
                .map<DropdownMenuItem<DistanceUnit>>((DistanceUnit unit) {
              return DropdownMenuItem<DistanceUnit>(
                value: unit,
                child: Text(
                    unit == DistanceUnit.kilometers ? 'Kilometers' : 'Miles'),
              );
            }).toList(),
          )
        ]),
      ),
    );
  }
}
