import 'package:flutter/material.dart';

class AppColors {
  // Table felt
  static const tableGreen = Color(0xFF1B5E20);
  static const tableDark = Color(0xFF0D3B0F);
  static const tableLight = Color(0xFF2E7D32);

  // Accent
  static const gold = Color(0xFFFFB300);
  static const goldDark = Color(0xFFFF8F00);
  static const amber = Color(0xFFFFCA28);

  // Primary action
  static const primaryRed = Color(0xFFD4380D);
  static const primaryRedLight = Color(0xFFFF5722);

  // Team colors
  static const redTeam = Color(0xFFE53935);
  static const blackTeam = Color(0xFF616161);

  // Panels
  static const panelBg = Color(0xFF263238);
  static const panelBorder = Color(0xFF37474F);

  // Cards
  static const cardWhite = Color(0xFFFAFAFA);
  static const cardShadow = Color(0x66000000);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.tableDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.gold,
        surface: AppColors.panelBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static BoxDecoration tableDecoration = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        AppColors.tableGreen,
        AppColors.tableDark,
      ],
    ),
  );

  static BoxDecoration panelDecoration = BoxDecoration(
    color: AppColors.panelBg.withOpacity(0.85),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.panelBorder, width: 1),
  );
}
