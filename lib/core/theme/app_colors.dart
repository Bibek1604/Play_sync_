import 'package:flutter/material.dart';

/// PlaySync Design System - Color Palette
/// Professional Gaming SaaS Style (Emerald → Teal Gradient)
/// Matches Next.js web version exactly
class AppColors {
  AppColors._();

  // ===================================
  // 🎨 PRIMARY BRAND COLORS (Emerald)
  // ===================================
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981); // ⭐ Main Primary
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // ===================================
  // 🎨 SECONDARY BRAND COLORS (Teal)
  // ===================================
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6); // ⭐ Gradient End
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E4A);

  // ===================================
  // 🎨 NEUTRAL COLORS (Slate)
  // ===================================
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ===================================
  // 🎨 ACCENT COLORS (Purple - Gaming Premium)
  // ===================================
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color purple300 = Color(0xFFD8B4FE);
  static const Color purple400 = Color(0xFFC084FC);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color purple700 = Color(0xFF7E22CE);
  static const Color purple800 = Color(0xFF6B21A8);
  static const Color purple900 = Color(0xFF581C87);

  // ===================================
  // 🎨 STATUS COLORS
  // ===================================
  // Success (Green)
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF065F46);

  // Error (Red)
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFF991B1B);

  // Warning (Amber)
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFF92400E);

  // Info (Blue)
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF1E40AF);

  // ===================================
  // 🎨 SEMANTIC COLORS - LIGHT MODE
  // ===================================
  static const Color backgroundPrimaryLight = Color(0xFFFFFFFF);
  static const Color backgroundSecondaryLight = Color(0xFFF8FAFC);
  static const Color backgroundTertiaryLight = Color(0xFFF1F5F9);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textTertiaryLight = Color(0xFF94A3B8);
  static const Color textInverseLight = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDefaultLight = Color(0xFFE2E8F0);
  static const Color borderDarkLight = Color(0xFFCBD5E1);

  // ===================================
  // 🎨 SEMANTIC COLORS - DARK MODE
  // ===================================
  static const Color backgroundPrimaryDark = Color(0xFF0F172A);
  static const Color backgroundSecondaryDark = Color(0xFF1E293B);
  static const Color backgroundTertiaryDark = Color(0xFF334155);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);
  static const Color textInverseDark = Color(0xFF0F172A);

  static const Color borderLightDark = Color(0xFF334155);
  static const Color borderDefaultDark = Color(0xFF475569);
  static const Color borderDarkDark = Color(0xFF64748B);

  // ===================================
  // 🎨 GRADIENTS
  // ===================================
  /// Primary brand gradient (Emerald → Teal)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald500, teal500],
  );

  /// Horizontal primary gradient
  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [emerald500, teal500],
  );

  /// Vertical primary gradient
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [emerald500, teal500],
  );

  /// Subtle gradient for cards
  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  // ===================================
  // 🎨 GLASSMORPHISM
  // ===================================
  static const Color glassLight = Color(0xF0FFFFFF);
  static const Color glassDark = Color(0xCC1E293B);
  
  static Color glassBackdropLight = Colors.white.withOpacity(0.7);
  static Color glassBackdropDark = const Color(0xFF1E293B).withOpacity(0.8);

  // ===================================
  // 🎨 SHADOWS
  // ===================================
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);
  
  // Emerald glow for buttons/cards
  static Color emeraldGlow = emerald500.withOpacity(0.3);
  static Color tealGlow = teal500.withOpacity(0.3);

  // ===================================
  // 🎨 OVERLAY COLORS
  // ===================================
  static Color overlayLight = Colors.black.withOpacity(0.5);
  static Color overlayDark = Colors.black.withOpacity(0.7);

  // ===================================
  // 🎨 DIVIDERS
  // ===================================
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ===================================
  // 🎨 SHIMMER COLORS
  // ===================================
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);
  
  static const Color shimmerBaseDark = Color(0xFF1E293B);
  static const Color shimmerHighlightDark = Color(0xFF334155);

  // ===================================
  // 🎨 CONVENIENCE GETTERS
  // ===================================
  /// Primary brand color (Emerald 500)
  static const Color primary = emerald500;
  static const Color primaryLight = emerald100;
  static const Color primaryDark = emerald700;

  /// Secondary brand color (Teal 500)
  static const Color secondary = teal500;
  static const Color secondaryLight = teal100;
  static const Color secondaryDark = teal700;

  /// Surface colors
  static const Color surfaceLight = backgroundSecondaryLight;
  static const Color surfaceDark = backgroundSecondaryDark;

  /// Background colors
  static const Color backgroundLight = backgroundPrimaryLight;
  static const Color backgroundDark = backgroundPrimaryDark;

  /// Shadow colors
  static const Color shadow = shadowLight;

  /// Disabled state
  static const Color disabled = slate400;

  /// Divider colors
  static const Color divider = dividerLight;
  static const Color dividerDarkMode = dividerDark;

  /// Card background colors
  static const Color cardLight = backgroundSecondaryLight;
  static const Color cardDark = backgroundSecondaryDark;

  /// Primary variant (darker emerald)
  static const Color primaryVariant = emerald700;

  /// Status colors for indicators
  static const Color statusSuccess = success;
  static const Color statusError = error;
  static const Color statusWarning = warning;
  static const Color statusInfo = info;
}
