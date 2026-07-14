import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';

/// Complete [ThemeData] for light and dark modes.
///
/// All colour values are sourced from [ColorTokens] — no hex literals
/// appear in feature code.
class AppTheme {
  AppTheme._();

  // ── Light theme ────────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: ColorTokens.accent,
      scaffoldBackgroundColor: ColorTokens.lightCanvas,
      cardColor: ColorTokens.lightCanvas,
      dividerColor: ColorTokens.lightBorder,
      disabledColor: ColorTokens.lightDisabled,
      textTheme: _buildTextTheme(ColorTokens.lightText, ColorTokens.lightTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.lightCanvas,
        foregroundColor: ColorTokens.lightText,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorTokens.lightText,
          letterSpacing: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.lightCanvas,
        selectedItemColor: ColorTokens.accent,
        unselectedItemColor: ColorTokens.lightDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ColorTokens.lightCanvas,
        selectedIconTheme: IconThemeData(color: ColorTokens.accent),
        unselectedIconTheme: IconThemeData(color: ColorTokens.lightDisabled),
        selectedLabelTextStyle: TextStyle(
          color: ColorTokens.accent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ColorTokens.lightDisabled,
          fontSize: 12,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: ColorTokens.lightCanvas,
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.lightCanvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorTokens.lightBorder),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorTokens.lightDisabled,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.accent,
          side: const BorderSide(color: ColorTokens.accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.lightError, width: 2),
        ),
        hintStyle: const TextStyle(
          color: ColorTokens.lightDisabled,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: ColorTokens.lightTextSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: ColorTokens.accent,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.lightSurface,
        selectedColor: ColorTokens.accent.withValues(alpha: 0.15),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: ColorTokens.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorTokens.lightCanvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.lightText,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorTokens.accent,
        linearTrackColor: ColorTokens.lightSurface,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ColorTokens.accent,
        unselectedLabelColor: ColorTokens.lightTextSecondary,
        indicatorColor: ColorTokens.accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorTokens.lightText,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: ColorTokens.accent,
      scaffoldBackgroundColor: ColorTokens.darkCanvas,
      cardColor: ColorTokens.darkSurface,
      dividerColor: ColorTokens.darkBorder,
      disabledColor: ColorTokens.darkDisabled,
      textTheme: _buildTextTheme(ColorTokens.darkText, ColorTokens.darkTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorTokens.darkCanvas,
        foregroundColor: ColorTokens.darkText,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorTokens.darkText,
          letterSpacing: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ColorTokens.darkCanvas,
        selectedItemColor: ColorTokens.accent,
        unselectedItemColor: ColorTokens.darkDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ColorTokens.darkCanvas,
        selectedIconTheme: IconThemeData(color: ColorTokens.accent),
        unselectedIconTheme: IconThemeData(color: ColorTokens.darkDisabled),
        selectedLabelTextStyle: TextStyle(
          color: ColorTokens.accent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ColorTokens.darkDisabled,
          fontSize: 12,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: ColorTokens.darkCanvas,
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorTokens.darkBorder),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ColorTokens.darkDisabled,
          disabledForegroundColor: Colors.white38,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.accent,
          side: const BorderSide(color: ColorTokens.accentDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.accentLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.darkError, width: 2),
        ),
        hintStyle: const TextStyle(
          color: ColorTokens.darkDisabled,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: ColorTokens.darkTextSecondary,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: ColorTokens.accentLight,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorTokens.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.darkSurface,
        selectedColor: ColorTokens.accent.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColorTokens.darkText,
        ),
        side: const BorderSide(color: ColorTokens.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorTokens.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.darkSurface,
        contentTextStyle: const TextStyle(color: ColorTokens.darkText, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorTokens.accent,
        linearTrackColor: ColorTokens.darkSurface,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ColorTokens.accentLight,
        unselectedLabelColor: ColorTokens.darkTextSecondary,
        indicatorColor: ColorTokens.accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ColorTokens.darkSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ColorTokens.darkBorder),
        ),
        textStyle: const TextStyle(color: ColorTokens.darkText, fontSize: 12),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color mainColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12, color: mainColor),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16, color: mainColor),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22, color: mainColor),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25, color: mainColor),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.29, color: mainColor),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33, color: mainColor),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.27, color: mainColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.50, letterSpacing: 0.15, color: mainColor),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1, color: mainColor),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50, letterSpacing: 0.50, color: mainColor),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, letterSpacing: 0.25, color: mainColor),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33, letterSpacing: 0.40, color: secondaryColor),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43, letterSpacing: 0.1, color: mainColor),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.50, color: secondaryColor),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.50, color: secondaryColor),
    );
  }
}
