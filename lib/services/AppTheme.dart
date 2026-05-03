import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppTheme extends ChangeNotifier {
  static final AppTheme _instance = AppTheme._internal();
  factory AppTheme() => _instance;
  AppTheme._internal();

  Color _appAccentColor = const Color(0xFF6366F1);
  Color get appAccentColor => _appAccentColor;

  void init() {
    try {
      var box = Hive.box('settingsBox');
      int? savedColor = box.get('accentColor');
      if (savedColor != null) {
        _appAccentColor = Color(savedColor);
      }
    } catch (e) {
      debugPrint("Theme Init Error: $e");
    }
  }

  void updateAccentColor(Color newColor) {
    _appAccentColor = newColor;
    notifyListeners(); // This makes the whole app change color instantly!
  }

  // LIGHT PALETTE
  static const Color cardLight = Colors.white;
  static const Color textLight = Color(0xFF1E293B);

  // DARK PALETTE
  static const Color textDark = Color(0xFFF1F5F9);

  static ThemeData _base(Brightness brightness, Color seed) {
    bool isDark = brightness == Brightness.dark;

    // 1. Generate the color scheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final Color lightBgTinted = Color.alphaBlend(
      seed.withOpacity(0.03),
      Colors.white,
    );
    final Color dynamicBg = isDark
        ? colorScheme.surfaceContainerLow // This adds more "tint" and lightness
        : lightBgTinted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme.copyWith(
        primary: seed,
        // Make sure surfaces are slightly lighter than the background for contrast
        surface: isDark ? colorScheme.surfaceContainer : lightBgTinted,
        onSurface: isDark ? textDark : textLight,
      ),
      scaffoldBackgroundColor: dynamicBg,
      cardTheme: CardThemeData(
        // Cards should be the 'High' or 'Highest' container to pop against the bg
        color: isDark ? colorScheme.surfaceContainerHigh : cardLight,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Input fields look best when slightly darker or lighter than the card
        fillColor: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dynamicBg, // Match the scaffold for a seamless look
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? textDark : textLight,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ThemeData get lightTheme => _base(Brightness.light, _appAccentColor);
  ThemeData get darkTheme => _base(Brightness.dark, _appAccentColor);
}
