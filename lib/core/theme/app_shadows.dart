import 'package:flutter/material.dart';
import 'app_colors.dart';

/// PlaySync Shadow System
/// Elevation-based shadows for depth and glassmorphism
class AppShadows {
  AppShadows._();

  // ===================================
  // 🌑 ELEVATION SHADOWS (Light Mode)
  // ===================================
  
  /// Extra Small - Minimal lift (cards, chips)
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Small - Subtle elevation (buttons, inputs)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium - Default cards
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      spreadRadius: -1,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 3,
      offset: Offset(0, 2),
    ),
  ];

  /// Large - Elevated panels
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  /// Extra Large - Modals, dialogs
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 6),
    ),
  ];

  /// 2XL - Heavy emphasis (tooltips, popovers)
  static const List<BoxShadow> xxl = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 48,
      spreadRadius: -8,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 10),
    ),
  ];

  // ===================================
  // 🌑 DARK MODE SHADOWS
  // ===================================
  
  static const List<BoxShadow> xsDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 8,
      spreadRadius: -1,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> xxlDark = [
    BoxShadow(
      color: Color(0x73000000),
      blurRadius: 48,
      spreadRadius: -8,
      offset: Offset(0, 20),
    ),
  ];

  // ===================================
  // 🌟 COLORED GLOW SHADOWS (Brand)
  // ===================================
  
  /// Emerald glow for primary actions
  static List<BoxShadow> emeraldGlow = [
    BoxShadow(
      color: AppColors.emerald500.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.emerald500.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Teal glow for secondary actions
  static List<BoxShadow> tealGlow = [
    BoxShadow(
      color: AppColors.teal500.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.teal500.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Purple accent glow
  static List<BoxShadow> purpleGlow = [
    BoxShadow(
      color: AppColors.purple500.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  /// Error glow
  static List<BoxShadow> errorGlow = [
    BoxShadow(
      color: AppColors.error.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Success glow
  static List<BoxShadow> successGlow = [
    BoxShadow(
      color: AppColors.success.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ===================================
  // 🌟 GLASSMORPHISM SHADOWS
  // ===================================
  
  /// Glass effect shadow (light mode)
  static final List<BoxShadow> glass = [
    BoxShadow(
      color: Colors.white.withOpacity(0.6),
      blurRadius: 0,
      offset: const Offset(0, 1),
    ),
    const BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 6),
    ),
  ];

  /// Glass effect shadow (dark mode)
  static final List<BoxShadow> glassDark = [
    BoxShadow(
      color: AppColors.slate700.withOpacity(0.4),
      blurRadius: 0,
      offset: const Offset(0, 1),
    ),
    const BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 6),
    ),
  ];

  // ===================================
  // 🎮 GAMING-SPECIFIC SHADOWS
  // ===================================
  
  /// Card hover effect
  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 32,
      spreadRadius: -4,
      offset: Offset(0, 16),
    ),
  ];

  /// Button pressed (inset effect)
  static const List<BoxShadow> inset = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 4,
      spreadRadius: -1,
      offset: Offset(0, 2),
    ),
  ];
}
