import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapgoal/src/views/goal_list_view.dart';

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
          restorationScopeId: 'app',
          supportedLocales: const [
            Locale('en', ''),
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                ColorScheme.fromSeed(seedColor: Colors.purple.shade900),
            textTheme: TextTheme(
              bodyLarge: GoogleFonts.openSans(
                fontSize: 18,
                // fontWeight: FontWeight.bold,
              ),
              titleLarge: GoogleFonts.abel(
                fontSize: 30,
              ),
              bodyMedium: GoogleFonts.openSans(fontSize: 20),
            ),
          ),
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
                  // case SampleItemDetailsView.routeName:
                  //   return const SampleItemDetailsView();
                  case GoalListView.routeName:
                  default:
                    return const GoalListView();
                }
              },
            );
          },
        );
      },
    );
  }
}
