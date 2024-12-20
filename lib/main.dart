import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app.dart';

import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsController = SettingsController(SettingsService());

  await settingsController.loadSettings();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp(settingsController: settingsController));
  });
}
