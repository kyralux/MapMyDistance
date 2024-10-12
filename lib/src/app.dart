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
                //Color(0xFF00aedb) primary
                //Color(0xFF00edce) sec
                primary: Color.fromARGB(255, 255, 255, 255),
                onPrimary: Colors.black,
                secondary: Color.fromARGB(255, 54, 212, 223),
                onSecondary: Color.fromARGB(255, 79, 79, 79),
                onTertiary: Colors.black, // Color.fromARGB(255, 61, 113, 255),
                tertiary: Color.fromARGB(255, 255, 230, 0),
                error: Colors.redAccent,
                onError: Colors.white,
                surface: Color.fromARGB(255, 255, 255, 255),
                onSurface: Colors.black,
                brightness: Brightness.light),
            textTheme: TextTheme(
              bodyLarge: GoogleFonts.openSans(fontSize: 18),
              titleLarge: GoogleFonts.abel(
                fontSize: 30,
              ),
              bodyMedium: GoogleFonts.openSans(fontSize: 20),
            ),
          ),
          // middleblue 00aedb, light 00edce, dark 003ef9, grey d6d6d6, yellow f9bb00 lighter yellow fff0c4
          // darkTheme: ThemeData(
          //   useMaterial3: true,
          //   colorScheme: ColorScheme.fromSeed(
          //       seedColor: Colors.blue, brightness: Brightness.dark),
          //   textTheme: TextTheme(
          //     bodyLarge: GoogleFonts.openSans(
          //       fontSize: 18,
          //       // fontWeight: FontWeight.bold,
          //     ),
          //     titleLarge: GoogleFonts.abel(
          //       fontSize: 30,
          //     ),
          //     bodyMedium: GoogleFonts.openSans(fontSize: 20), // History

          //     //handwritte: caveat
          //   ),
          // ),
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
