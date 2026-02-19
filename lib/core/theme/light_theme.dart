import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';

/// PlaySync Light Theme
/// Premium, clean design with emerald→teal gradient branding
class LightTheme {
  LightTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,

      // ===================================
      // 🎨 COLOR SCHEME
      // ===================================
      colorScheme: const ColorScheme.light(
        primary: AppColors.emerald500,
        onPrimary: Colors.white,
        primaryContainer: AppColors.emerald100,
        onPrimaryContainer: AppColors.emerald900,
        
        secondary: AppColors.teal500,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.teal100,
        onSecondaryContainer: AppColors.teal900,
        
        tertiary: AppColors.purple500,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.purple100,
        onTertiaryContainer: AppColors.purple900,
        
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.errorDark,
        
        surface: AppColors.backgroundPrimaryLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerHighest: AppColors.backgroundSecondaryLight,
        
        outline: AppColors.borderDefaultLight,
        outlineVariant: AppColors.borderLight,
        
        shadow: AppColors.shadowLight,
        
        scrim: Color(0x80000000),
      ),

      // ===================================
      // 🔤 TYPOGRAPHY
      // ===================================
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ===================================
      // 🎯 COMPONENT THEMES
      // ===================================
      
      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.card,
          side: BorderSide(
            color: AppColors.borderDefaultLight,
            width: 1,
          ),
        ),
        margin: AppSpacing.paddingMD,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(88, AppSpacing.buttonHeightMedium),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          textStyle: AppTypography.button,
          side: const BorderSide(color: AppColors.borderDefaultLight, width: 1.5),
          minimumSize: const Size(88, AppSpacing.buttonHeightMedium),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          textStyle: AppTypography.button,
          minimumSize: const Size(88, AppSpacing.buttonHeightMedium),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondaryLight,
        contentPadding: AppSpacing.paddingMD,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.borderDefaultLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.borderDefaultLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.emerald500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondaryLight,
        selectedColor: AppColors.emerald100,
        disabledColor: AppColors.backgroundTertiaryLight,
        labelStyle: AppTypography.labelMedium,
        padding: AppSpacing.paddingSM,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.chip,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald500,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXL,
        ),
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.modal,
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slate800,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusMD,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: AppSpacing.dividerThickness,
        space: AppSpacing.md,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.emerald500,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald500,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald500;
          }
          return AppColors.slate300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald200;
          }
          return AppColors.slate200;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald500;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald500;
          }
          return AppColors.slate400;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.emerald500,
        inactiveTrackColor: AppColors.emerald200,
        thumbColor: AppColors.emerald500,
        overlayColor: AppColors.emerald500.withOpacity(0.2),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryLight,
        size: AppSpacing.iconSize,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.backgroundPrimaryLight,
    );
  }
}
