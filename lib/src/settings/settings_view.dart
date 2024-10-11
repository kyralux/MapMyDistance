import 'package:flutter/material.dart';

import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            return;
            // // This means the user initiated the pop action
            // Future.delayed(Duration.zero, () {
            //   // Use the Navigator to pop with the desired result
            //   Navigator.of(context).pop(controller.distanceUnit);
            // });
          }
          return;
          //   return;
          // }
          // if (didPop) {
          //   Future.delayed(Duration.zero, () {
          //     Navigator.of(context, rootNavigator: true)
          //         .pop(controller.distanceUnit);
          //     //Navigator.pop(context, controller.distanceUnit);
          //   });
          //   return;
          // }
        },
        child: Scaffold(
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
                    child: Text(unit == DistanceUnit.kilometers
                        ? 'Kilometers'
                        : 'Miles'),
                  );
                }).toList(),
              )
            ]),
          ),
        ));
  }
}
