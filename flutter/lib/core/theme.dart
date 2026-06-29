import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF00BCD4);
  static const _secondaryColor = Color(0xFF26C6DA);
  static const _surfaceColor = Color(0xFF1A1A2E);
  static const _backgroundColor = Color(0xFF0F0F23);
  static const _errorColor = Color(0xFFEF5350);
  static const _successColor = Color(0xFF66BB6A);
  static const _warningColor = Color(0xFFFFCA28);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _primaryColor,
          secondary: _secondaryColor,
          surface: _surfaceColor,
          error: _errorColor,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceColor,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: _surfaceColor.withValues(alpha: 0.8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _surfaceColor,
          indicatorColor: _primaryColor.withValues(alpha: 0.2),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceColor.withValues(alpha: 0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryColor),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceColor.withValues(alpha: 0.6),
          selectedColor: _primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  static const sensorColors = {
    'presence': Color(0xFF66BB6A),
    'breathing': Color(0xFF42A5F5),
    'heartrate': Color(0xFFEF5350),
    'pose': Color(0xFFFFCA28),
    'fall': Color(0xFFFF7043),
    'sleep': Color(0xFF7E57C2),
  };
}
