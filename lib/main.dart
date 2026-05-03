import 'package:flutter/material.dart';
import 'navigation_menu.dart';
//  SCREENS
//  SERVICES
import '../services/database_service.dart';
import '../services/AppTheme.dart';
//------------------------------------------------------------------------------

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  await DatabaseService.init();

  themeNotifier.value = ThemeMode.dark;
  AppTheme().init();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppTheme(),
      builder: (context, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, ThemeMode currentMode, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Attendance Tracker',
              darkTheme: AppTheme().darkTheme,
              themeMode: currentMode,
              home: NavigationMenu(),
            );
          },
        );
      },
    );
  }
}
