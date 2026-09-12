import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0B11);
  static const backgroundRaised = Color(0xFF101018);
  static const surface = Color(0xFF181820);
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textTertiary = Color(0xFF71717A);
  static const accent = Color(0xFFA78BFA);
  static const accentStrong = Color(0xFF9D7CFF);
  static const error = Color(0xFFFF8E8E);
}

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.accentStrong,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: Color(0xFF171221),
    onSecondary: Color(0xFF171221),
    onSurface: AppColors.textPrimary,
    onError: Color(0xFF250909),
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.white.withValues(alpha: 0.035),
    dividerColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: Color(0x449D7CFF),
      selectionHandleColor: AppColors.accent,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
