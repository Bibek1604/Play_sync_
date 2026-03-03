import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// PlaySync App Theme — Clean Professional Gray-Blue Design System
///
/// Brand: Deep Blue #1E3A8A · Medium Blue #3B82F6 · Accent Gray #6B7280
/// Typography: Inter (body 16px min) · WCAG AA contrast
/// Border radius: 12–16px · Transitions: 250–300ms
class AppTheme {
  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.light(
        primary:           AppColors.primary,
        onPrimary:         AppColors.textOnPrimary,
        primaryContainer:  AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary:         AppColors.secondary,
        onSecondary:       Colors.white,
        secondaryContainer: AppColors.secondaryLight,
        tertiary:          AppColors.accent,
        surface:           AppColors.surface,
        onSurface:         AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLight,
        error:             AppColors.error,
        onError:           Colors.white,
        outline:           AppColors.border,
        outlineVariant:    AppColors.borderSubtle,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ── Page transitions (250-300ms) ──────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor:     AppColors.background,
        foregroundColor:     AppColors.textPrimary,
        centerTitle:         false,
        surfaceTintColor:    Colors.transparent,
        shadowColor:         AppColors.border,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.primary, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ── Elevated Button ───────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  AppColors.primary,
          foregroundColor:  AppColors.textOnPrimary,
          elevation:        0,
          shadowColor:      Colors.transparent,
          padding:   const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          animationDuration: const Duration(milliseconds: 250),
        ),
      ),

      // ── Filled Button ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side:    const BorderSide(color: AppColors.border, width: 1.5),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter', color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(
          fontFamily: 'Inter', color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        errorStyle: const TextStyle(
          fontFamily: 'Inter', color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          if (states.contains(WidgetState.error))   return AppColors.error;
          return AppColors.textTertiary;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          if (states.contains(WidgetState.error))   return AppColors.error;
          return AppColors.textTertiary;
        }),
      ),

      // ── Text Theme (Inter, 16px min body) ─────────────────────────────
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamily: 'Inter', fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.0),
        displayMedium:  TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        displaySmall:   TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
        headlineLarge:  TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.2),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.1),
        headlineSmall:  TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge:     TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.1),
        titleMedium:    TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge:      TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5),
        bodyMedium:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
        bodySmall:      TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4),
        labelLarge:     TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium:    TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall:     TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.4),
      ),

      // ── Card Theme ────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:       AppColors.surface,
        elevation:   0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Navigation Bar ────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation:           0,
        backgroundColor:     AppColors.surface,
        surfaceTintColor:    Colors.transparent,
        shadowColor:         AppColors.border,
        indicatorColor:      AppColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 23);
          }
          return const IconThemeData(color: AppColors.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Inter', color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(
            fontFamily: 'Inter', color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height:       64,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor:         AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor:     AppColors.primary,
        indicatorSize:      TabBarIndicatorSize.label,
        labelStyle:   TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor:       AppColors.border,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:   AppColors.surface,
        surfaceTintColor:  Colors.transparent,
        elevation:         0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary, height: 1.5),
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        elevation:  0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 1, space: 1),

      // ── Chip ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor:   AppColors.primaryLight,
        labelStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.circle),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Icon Theme ────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3:      true,
      brightness:        Brightness.dark,
      fontFamily:        'Inter',
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary:          AppColors.primaryAlt,
        onPrimary:        Colors.white,
        secondary:        AppColors.accent,
        surface:          AppColors.cardDark,
        onSurface:        Colors.white,
        error:            AppColors.error,
        outline:          Color(0xFF334155),
      ),
    );
  }
}

/// 8-px spacing scale
class AppSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;
}

/// Border-radius scale (12-16px default range)
class AppRadius {
  static const double xs     = 4.0;
  static const double sm     = 8.0;
  static const double md     = 12.0;
  static const double lg     = 14.0;
  static const double xl     = 16.0;
  static const double xxl    = 20.0;
  static const double xxxl   = 24.0;
  static const double circle = 50.0;
}
