import 'package:flutter/material.dart';

/// PlaySync Design System — Premium 2026 Light Mode Color Kit
/// Inspired by Figma, Linear, Slack: minimal, high-contrast, trustworthy.
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  /// Main scaffold — very light cool-gray/white
  static const Color background    = Color(0xFFF8FAFC);
  /// Pure white for cards and elevated surfaces
  static const Color surface       = Color(0xFFFFFFFF);
  /// Off-white tertiary surface (input fills, list tiles)
  static const Color surfaceLight  = Color(0xFFF1F5F9);
  /// Muted surface (skeleton loaders, disabled areas)
  static const Color surfaceMuted  = Color(0xFFE2E8F0);

  // ── Borders & Dividers ───────────────────────────────────────────────────
  static const Color border        = Color(0xFFE2E8F0);
  static const Color borderSubtle  = Color(0xFFF1F5F9);

  // ── Primary — Indigo ─────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF6366F1);   // indigo-500
  static const Color primaryDark   = Color(0xFF4F46E5);   // indigo-600
  static const Color primaryLight  = Color(0xFFEEF2FF);   // indigo-50
  static const Color primaryAlt    = Color(0xFF818CF8);   // indigo-400

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);   // slate-900
  static const Color textSecondary = Color(0xFF64748B);   // slate-500
  static const Color textTertiary  = Color(0xFF94A3B8);   // slate-400
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
  /// Blue — info, links
  static const Color info          = Color(0xFF3B82F6);
  static const Color infoLight     = Color(0xFFDBEAFE);

  // ── Kept for backwards-compat ─────────────────────────────────────────────
  static const Color secondary         = Color(0xFFF8FAFC);
  static const Color secondaryDark     = Color(0xFF6366F1);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
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
