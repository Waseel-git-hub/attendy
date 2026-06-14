import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppTheme extends ChangeNotifier {
  static final AppTheme _instance = AppTheme._internal();
  factory AppTheme() => _instance;
  AppTheme._internal();

  Color _accentColor = const Color(0xFF6366F1);

  Color get accentColor => _accentColor;

  void init() {
    try {
      final box = Hive.box('settingsBox');
      final savedColor = box.get('accentColor');

      if (savedColor != null) {
        _accentColor = Color(savedColor);
      }
    } catch (e) {
      debugPrint('Theme Init Error: $e');
    }
  }

  void updateAccentColor(Color color) {
    _accentColor = color;
    Hive.box('settingsBox').put('accentColor', color.value);
    notifyListeners();
  }

  ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        seed: _accentColor,
      );

  ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        seed: _accentColor,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color seed,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      primary: seed,

      // Background
      surface: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),

      // Normal Cards
      surfaceContainerLow: isDark ? const Color(0xFF1F2937) : Colors.white,

      // Important Cards
      surfaceContainerHigh:
          isDark ? const Color(0xFF273449) : const Color(0xFFF1F5F9),

      // Inputs
      surfaceContainerLowest: isDark ? const Color(0xFF0F172A) : Colors.white,

      // Text
      onSurface: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),

      onSurfaceVariant:
          isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),

      // Borders
      outlineVariant:
          isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: scheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
