import 'package:flutter/material.dart';

/// PlaySync Design System - Professional Green Theme
/// Strict color palette for consistent UI across the application
class AppColors {
  // ============================================
  // PRIMARY BACKGROUNDS
  // ============================================
  /// Pure white background for main surfaces
  static const Color background = Color(0xFFFFFFFF);

  /// Soft light gray for cards, sections, and secondary surfaces
  static const Color surfaceLight = Color(0xFFF8F9FA);

  /// Tertiary background for subtle contrast
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  // ============================================
  // PRIMARY ACCENT COLOR - GREEN
  // ============================================
  /// Main brand green - used for primary buttons, icons, and focus states
  static const Color primary = Color(0xFF16A34A);

  /// Alternative primary green shade
  static const Color primaryAlt = Color(0xFF22C55E);

  /// Hover/pressed state for green elements - darker shade
  static const Color primaryDark = Color(0xFF15803D);

  /// Light disabled/inactive green state
  static const Color primaryLight = Color(0xDCEDC5C4);

  // ============================================
  // TEXT COLORS
  // ============================================
  /// Primary text color - dark charcoal for headings and body text
  static const Color textPrimary = Color(0xFF1F2937);

  /// Secondary text - medium gray for subheadings and hints
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text - light gray for disabled or less important text
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text on colored backgrounds (contrasting white)
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ============================================
  // BORDER & DIVIDER
  // ============================================
  /// Light gray border for inputs, cards, and dividers
  static const Color border = Color(0xFFE5E7EB);

  /// Subtle border for less prominent divisions
  static const Color borderSubtle = Color(0xFFF3F4F6);

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  /// Error/negative actions - red
  static const Color error = Color(0xFFDC2626);

  /// Error light background
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Success state - green
  static const Color success = Color(0xFF059669);

  /// Success light background
  static const Color successLight = Color(0xEDF2F7);

  /// Warning/caution - amber
  static const Color warning = Color(0xFFF59E0B);

  /// Warning light background
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Info/notice - blue
  static const Color info = Color(0xFF0EA5E9);

  /// Info light background
  static const Color infoLight = Color(0xFFF0F9FF);

  // ============================================
  // DISABLE & OVERLAY
  // ============================================
  /// Disabled element color
  static const Color disabled = Color(0xFFD1D5DB);

  /// Semi-transparent overlay for modals
  static const Color overlay = Color(0x99000000);

  /// Light overlay for hover effects
  static const Color overlayLight = Color(0x08000000);

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get green color with custom opacity (0-1)
  static Color primaryWithOpacity(double opacity) {
    return primary.withValues(alpha: opacity);
  }

  /// Get text color adjusted for theme brightness
  static Color textForBackground(Color background) {
    final luminance = background.value >> 24;
    return luminance > 128 ? textPrimary : textOnPrimary;
  }
}
