import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Dark Theme Configuration
/// 
/// Complete dark theme for the PlaySync app.
class DarkTheme {
  // Prevent instantiation
  DarkTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: AppTypography.fontFamily,

        // Color Scheme
        colorScheme: const ColorScheme.dark(
          primary: AppColors.secondary,
          primaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondaryLight,
          secondaryContainer: AppColors.secondary,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: AppColors.textPrimaryDark,
          onError: Colors.white,
        ),

        // Scaffold
        scaffoldBackgroundColor: AppColors.backgroundDark,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),

        // Card
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 2,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.black,
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
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary),
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
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: AppTypography.button,
          ),
        ),

        // Input Decoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardDark,
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
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
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
            color: AppColors.textSecondaryDark,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.disabled,
          ),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.textSecondaryDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          elevation: 4,
        ),

        // Divider
        dividerTheme: DividerThemeData(
          color: Colors.grey[800],
          thickness: 1,
        ),

        // Icon
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
        ),

        // Text Theme
        textTheme: TextTheme(
          displayLarge: AppTypography.h1.copyWith(color: AppColors.textPrimaryDark),
          displayMedium: AppTypography.h2.copyWith(color: AppColors.textPrimaryDark),
          displaySmall: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
          headlineLarge: AppTypography.h3.copyWith(color: AppColors.textPrimaryDark),
          headlineMedium: AppTypography.h4.copyWith(color: AppColors.textPrimaryDark),
          headlineSmall: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
          titleLarge: AppTypography.h5.copyWith(color: AppColors.textPrimaryDark),
          titleMedium: AppTypography.h6.copyWith(color: AppColors.textPrimaryDark),
          titleSmall: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryDark),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
          bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
          labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryDark),
          labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark),
          labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryDark),
        ),
      );
}
