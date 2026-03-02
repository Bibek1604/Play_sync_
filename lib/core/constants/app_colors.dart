import 'package:flutter/material.dart';

/// PlaySync Design System — Clean, Professional Color Kit
/// Background: Pure white · Primary: Green · Text: Dark charcoal
/// Rule: No blue in primary/secondary. Green = action. Gray = structure.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  /// Main scaffold — pure white
  static const Color background    = Color(0xFFFFFFFF);
  /// Card surfaces — very light gray
  static const Color surface       = Color(0xFFF8F9FA);
  /// Off-white tertiary surface (input fills, list tiles)
  static const Color surfaceLight  = Color(0xFFF1F5F9);
  /// Muted surface (skeleton loaders, disabled areas)
  static const Color surfaceMuted  = Color(0xFFE2E8F0);

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color border        = Color(0xFFE5E7EB);
  static const Color borderSubtle  = Color(0xFFF1F5F9);
  static const Color borderDark    = Color(0xFF374151);   // gray-700 (dark mode borders)

  // ── Primary — Green ──────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF16A34A);   // green-600
  static const Color primaryDark   = Color(0xFF15803D);   // green-700 (hover)
  static const Color primaryLight  = Color(0xFFF0FDF4);   // green-50
  static const Color primaryAlt    = Color(0xFF22C55E);   // green-500

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1F2937);   // gray-800 (dark charcoal)
  static const Color textSecondary = Color(0xFF6B7280);   // gray-500
  static const Color textTertiary  = Color(0xFF9CA3AF);   // gray-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  /// Emerald — success, online, joined
  static const Color success       = Color(0xFF10B981);
  static const Color successLight  = Color(0xFFD1FAE5);
  static const Color successDark   = Color(0xFF059669);
  /// Orange — notifications, warnings, pending
  static const Color warning       = Color(0xFFF97316);
  static const Color warningLight  = Color(0xFFFFEDD5);
  static const Color warningDark   = Color(0xFFEA580C);
  /// Red — errors, destructive
  static const Color error         = Color(0xFFEF4444);
  static const Color errorLight    = Color(0xFFFEE2E2);
  /// Teal — info, links (no blue)
  static const Color info          = Color(0xFF0D9488);
  static const Color infoLight     = Color(0xFFCCFBF1);

  // ── Kept for backwards-compat ─────────────────────────────────────────────
  static const Color secondary         = Color(0xFFF8FAFC);
  static const Color secondaryDark     = Color(0xFF16A34A);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color backgroundDark    = Color(0xFF0F172A);
  static const Color cardDark          = Color(0xFF1E293B);

  // ── Overlay & disabled ───────────────────────────────────────────────────
  static const Color disabled      = Color(0xFFCBD5E1);
  static const Color overlay       = Color(0x80000000);
  static const Color overlayLight  = Color(0x0A000000);

  // ── Rank colors ──────────────────────────────────────────────────────────
  static const Color rankGold   = Color(0xFFF59E0B);
  static const Color rankSilver = Color(0xFF94A3B8);
  static const Color rankBronze = Color(0xFFB45309);

  // ── Helpers ──────────────────────────────────────────────────────────────
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  static Color withOpacity(Color c, double opacity) =>
      c.withValues(alpha: opacity);
}
