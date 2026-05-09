import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'navigation_menu.dart';
//  SCREENS
//  SERVICES
import '../services/database_service.dart';
import '../services/AppTheme.dart';
//------------------------------------------------------------------------------

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await DatabaseService.init();

  final settingsBox = await Hive.openBox('settingsBox');
  final int savedThemeIndex = settingsBox.get(
    'themeMode',
    defaultValue: ThemeMode.system.index,
  );
  themeNotifier.value = ThemeMode.values[savedThemeIndex];
  AppTheme().init();

  runApp(const MainApp());
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
              theme: AppTheme().lightTheme,
              darkTheme: AppTheme().darkTheme,
              themeMode: currentMode,
              home: const NavigationMenu(),
            );
          },
        );
      },
    );
  }
}
