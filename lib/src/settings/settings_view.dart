import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        }
        return;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            color: Theme.of(context).colorScheme.secondary,
            height: 15,
          ),
          const SizedBox(height: 30),
          Container(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                AppLocalizations.of(context)!.settingsTheme,
              )),
          DropdownButton<ThemeMode>(
            menuWidth: double.infinity,
            padding: const EdgeInsets.only(left: 30),
            underline: Container(),
            iconEnabledColor: Theme.of(context).colorScheme.secondary,
            dropdownColor: Theme.of(context).colorScheme.secondary,
            value: controller.themeMode,
            onChanged: controller.updateThemeMode,
            items: const [
              DropdownMenuItem(
                alignment: Alignment.center,
                value: ThemeMode.system,
                child: Text('System Theme'),
              ),
              DropdownMenuItem(
                alignment: Alignment.center,
                value: ThemeMode.light,
                child: Text('Light Theme'),
              ),
              DropdownMenuItem(
                alignment: Alignment.center,
                value: ThemeMode.dark,
                child: Text('Dark Theme'),
              )
            ],
          ),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                AppLocalizations.of(context)!.settingsUnit,
              )),
          DropdownButton<DistanceUnit>(
            menuWidth: double.infinity,
            padding: const EdgeInsets.only(left: 30),
            underline: Container(),
            iconEnabledColor: Theme.of(context).colorScheme.secondary,
            dropdownColor: Theme.of(context).colorScheme.secondary,
            value: controller.distanceUnit,
            onChanged: controller.updateDistanceUnit,
            items: DistanceUnit.values
                .map<DropdownMenuItem<DistanceUnit>>((DistanceUnit unit) {
              return DropdownMenuItem<DistanceUnit>(
                alignment: Alignment.center,
                value: unit,
                child: Text(unit == DistanceUnit.kilometers
                    ? AppLocalizations.of(context)!.kilometers
                    : AppLocalizations.of(context)!.miles),
              );
            }).toList(),
          )
        ]),
      ),
    );
  }
}
