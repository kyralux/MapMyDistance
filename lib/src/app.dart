import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapgoal/src/views/main_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  TextTheme getTextThemes() {
    return TextTheme(
      bodyLarge: GoogleFonts.openSans(fontSize: 18),
      titleLarge: GoogleFonts.abel(fontSize: 30, fontWeight: FontWeight.w900),
      bodyMedium: GoogleFonts.openSans(fontSize: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          restorationScopeId: 'app',
          theme: ThemeData(
            useMaterial3: true,
            focusColor: Colors.pink,
            colorScheme: const ColorScheme(
                primary: Color.fromARGB(255, 255, 255, 255),
                onPrimary: Colors.black,
                secondary: Color.fromARGB(255, 54, 212, 223),
                onSecondary: Color.fromARGB(255, 79, 79, 79),
                onTertiary: Colors.white, // Color.fromARGB(255, 61, 113, 255),
                tertiary: Color.fromARGB(
                    255, 246, 174, 31), //Color.fromARGB(255, 255, 230, 0),
                error: Colors.redAccent,
                onError: Colors.white,
                surface: Color.fromARGB(255, 255, 255, 255),
                onSurface: Colors.black,
                brightness: Brightness.light),
            textTheme: getTextThemes(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            focusColor: Colors.pink,
            colorScheme: const ColorScheme(
                primary: Color.fromARGB(255, 57, 57, 57),
                onPrimary: Color.fromARGB(255, 255, 255, 255),
                secondary: Color.fromARGB(255, 2, 88, 94),
                onSecondary: Color.fromARGB(255, 199, 199, 199),
                onTertiary: Colors.black, // Color.fromARGB(255, 61, 113, 255),
                tertiary: Color.fromARGB(255, 144, 0, 108),
                error: Colors.redAccent,
                onError: Colors.white,
                surface: Color.fromARGB(255, 57, 57, 57),
                onSurface: Color.fromARGB(255, 231, 231, 231),
                brightness: Brightness.dark),
            textTheme: getTextThemes(),
          ),
          themeMode: settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case GoalListView.routeName:
                  default:
                    return GoalListView(controller: settingsController);
                }
              },
            );
          },
        );
      },
    );
  }
}
