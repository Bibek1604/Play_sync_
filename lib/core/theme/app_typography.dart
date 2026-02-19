import 'package:flutter/material.dart';

/// PlaySync Typography System
/// Uses OpenSans font exclusively for premium branding
class AppTypography {
  AppTypography._();

  // ===================================
  // 🔤 FONT FAMILY
  // ===================================
  static const String fontFamily = 'OpenSans';

  // ===================================
  // 🔤 DISPLAY TEXT (Extra Large)
  // ===================================
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.22,
  );

  // ===================================
  // 🔤 HEADLINES
  // ===================================
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ===================================
  // 🔤 TITLES
  // ===================================
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ===================================
  // 🔤 BODY TEXT
  // ===================================
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ===================================
  // 🔤 LABELS
  // ===================================
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ===================================
  // 🔤 CUSTOM STYLES (Gaming/SaaS specific)
  // ===================================
  
  /// Button text - uppercase, bold, wide tracking
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.25,
    height: 1.0,
  );

  /// Button text large
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.0,
  );

  /// Overline text - small, uppercase
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  );

  /// Caption text
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Mono/Code text (fallback to system monospace)
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  // ===================================
  // 🔤 GAMING-SPECIFIC STYLES
  // ===================================
  
  /// Large score/stat number
  static const TextStyle statNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.0,
  );

  /// Player name in game
  static const TextStyle playerName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Game title
  static const TextStyle gameTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Chat message
  static const TextStyle chatMessage = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  /// System message
  static const TextStyle systemMessage = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    fontStyle: FontStyle.italic,
  );

  // ===================================
  // 🔤 CONVENIENCE GETTERS (h1-h6)
  // ===================================
  /// Heading 1 - Largest heading
  static const TextStyle h1 = headlineLarge;
  
  /// Heading 2
  static const TextStyle h2 = headlineMedium;
  
  /// Heading 3
  static const TextStyle h3 = headlineSmall;
  
  /// Heading 4
  static const TextStyle h4 = titleLarge;
  
  /// Heading 5
  static const TextStyle h5 = titleMedium;
  
  /// Heading 6 - Smallest heading
  static const TextStyle h6 = titleSmall;
  
  /// Default body text
  static const TextStyle body = bodyMedium;
}
