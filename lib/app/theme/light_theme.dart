import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Light Theme Configuration
/// 
/// Complete light theme for the PlaySync app.
class LightTheme {
  // Prevent instantiation
  LightTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,

        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.primaryLight,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryLight,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
        ),

        // Scaffold
        scaffoldBackgroundColor: AppColors.backgroundLight,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Card
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.medium,
            ),
            textStyle: AppTypography.button,
          ),
        ),

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.medium,
            ),
            textStyle: AppTypography.button,
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: AppTypography.button,
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: AppRadius.medium,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.medium,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.medium,
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.medium,
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.medium,
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.disabled,
          ),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondaryLight,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
        ),

        // Text Theme
        textTheme: TextTheme(
          displayLarge: AppTypography.h1.copyWith(color: AppColors.textPrimaryLight),
          displayMedium: AppTypography.h2.copyWith(color: AppColors.textPrimaryLight),
          displaySmall: AppTypography.h3.copyWith(color: AppColors.textPrimaryLight),
          headlineLarge: AppTypography.h3.copyWith(color: AppColors.textPrimaryLight),
          headlineMedium: AppTypography.h4.copyWith(color: AppColors.textPrimaryLight),
          headlineSmall: AppTypography.h5.copyWith(color: AppColors.textPrimaryLight),
          titleLarge: AppTypography.h5.copyWith(color: AppColors.textPrimaryLight),
          titleMedium: AppTypography.h6.copyWith(color: AppColors.textPrimaryLight),
          titleSmall: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryLight),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryLight),
          bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryLight),
          labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight),
          labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
        ),
      );
}
