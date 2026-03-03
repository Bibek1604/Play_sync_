import 'package:flutter/material.dart';

/// PlaySync Design System — Clean, Professional Gray-Blue Palette
///
/// Brand Palette:
///   Deep Blue   #1E3A8A — primary actions, trust, depth
///   Medium Blue #3B82F6 — secondary actions, highlights
///   Accent Gray #6B7280 — subtle accents
///   White       #FFFFFF — clean backgrounds
///   Charcoal    #111827 / #374151 — readable text (WCAG AA)
///
/// The sidebar uses a smooth gray→blue gradient for a clean,
/// professional brand impression.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF9FAFB);   // Gray-50 tinted white
  static const Color surface       = Color(0xFFFFFFFF);    // Pure white cards
  static const Color surfaceLight  = Color(0xFFF3F4F6);   // Gray-100
  static const Color surfaceMuted  = Color(0xFFE5E7EB);   // Gray-200

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color border        = Color(0xFFD1D5DB);   // Gray-300 (more visible)
  static const Color borderSubtle  = Color(0xFFE5E7EB);   // Gray-200
  static const Color borderDark    = Color(0xFF4B5563);   // Gray-600

  // ── Brand — Deep Blue (Primary) ──────────────────────────────────────────
  static const Color primary       = Color(0xFF1E3A8A);   // Blue-800
  static const Color primaryDark   = Color(0xFF1E3070);   // Darker blue (hover/press)
  static const Color primaryLight  = Color(0xFFDBEAFE);   // Blue-100 tint
  static const Color primaryAlt    = Color(0xFF2563EB);   // Blue-600 variant

  // ── Brand — Medium Blue (Secondary) ──────────────────────────────────────
  static const Color secondary     = Color(0xFF3B82F6);   // Blue-500
  static const Color secondaryDark = Color(0xFF2563EB);   // Blue-600
  static const Color secondaryLight = Color(0xFFEFF6FF);  // Blue-50 tint

  // ── Accent Gray ──────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF6B7280);   // Gray-500
  static const Color accentLight   = Color(0xFFF3F4F6);   // Gray-100

  // ── Sidebar Gradient ─────────────────────────────────────────────────────
  static const List<Color> sidebarGradient = [
    Color(0xFF1E3A8A),   // Blue-800
    Color(0xFF2563EB),   // Blue-600
    Color(0xFF3B82F6),   // Blue-500
  ];

  // ── Text (WCAG AA compliant) ─────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);   // Gray-900
  static const Color textSecondary = Color(0xFF374151);   // Gray-700 (better readability)
  static const Color textTertiary  = Color(0xFF6B7280);   // Gray-500
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF059669);   // Emerald-600
  static const Color successLight  = Color(0xFFD1FAE5);
  static const Color successDark   = Color(0xFF047857);
  static const Color warning       = Color(0xFFD97706);   // Amber-600
  static const Color warningLight  = Color(0xFFFEF3C7);
  static const Color warningDark   = Color(0xFFB45309);
  static const Color error         = Color(0xFFDC2626);   // Red-600
  static const Color errorLight    = Color(0xFFFEE2E2);
  static const Color info          = Color(0xFF3B82F6);   // Blue-500
  static const Color infoLight     = Color(0xFFDBEAFE);

  // ── Dark mode ────────────────────────────────────────────────────────────
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color backgroundDark    = Color(0xFF0F172A);  // Slate-900
  static const Color cardDark          = Color(0xFF1E293B);  // Slate-800
  static const Color surfaceDark       = Color(0xFF1E293B);

  // ── Overlay & disabled ───────────────────────────────────────────────────
  static const Color disabled      = Color(0xFF9CA3AF);   // Gray-400
  static const Color overlay       = Color(0x80000000);
  static const Color overlayLight  = Color(0x0A000000);

  // ── Rank colors ──────────────────────────────────────────────────────────
  static const Color rankGold   = Color(0xFFF59E0B);
  static const Color rankSilver = Color(0xFF94A3B8);
  static const Color rankBronze = Color(0xFFB45309);

  // ── Chat bubbles ─────────────────────────────────────────────────────────
  static const Color chatBubbleOwn   = Color(0xFF1E3A8A);   // Primary blue
  static const Color chatBubbleOther = Color(0xFF374151);   // Gray-700

  // ── Helpers ──────────────────────────────────────────────────────────────
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  static Color withOpacity(Color c, double opacity) =>
      c.withValues(alpha: opacity);
}
