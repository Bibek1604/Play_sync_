import 'package:flutter/material.dart';

/// PlaySync Spacing System
/// Based on 8px grid for consistent spacing
class AppSpacing {
  AppSpacing._();

  // ===================================
  // 📏 BASE SPACING (8px grid)
  // ===================================
  static const double xs = 4.0;    // 0.5 * 8
  static const double sm = 8.0;    // 1 * 8
  static const double md = 16.0;   // 2 * 8
  static const double lg = 24.0;   // 3 * 8
  static const double xl = 32.0;   // 4 * 8
  static const double xxl = 48.0;  // 6 * 8
  static const double xxxl = 64.0; // 8 * 8

  // ===================================
  // 📏 GRANULAR SPACING
  // ===================================
  static const double space0 = 0.0;
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space7 = 28.0;
  static const double space8 = 32.0;
  static const double space9 = 36.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space14 = 56.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;
  static const double space24 = 96.0;
  static const double space32 = 128.0;

  // ===================================
  // 📏 PADDING SHORTCUTS
  // ===================================
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: xl);

  // Page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets pagePaddingHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pagePaddingVertical = EdgeInsets.symmetric(vertical: lg);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(lg);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  // ===================================
  // 📏 GAP VALUES (for Gaps in Flex widgets)
  // ===================================
  static const SizedBox gapXS = SizedBox(width: xs, height: xs);
  static const SizedBox gapSM = SizedBox(width: sm, height: sm);
  static const SizedBox gapMD = SizedBox(width: md, height: md);
  static const SizedBox gapLG = SizedBox(width: lg, height: lg);
  static const SizedBox gapXL = SizedBox(width: xl, height: xl);
  static const SizedBox gapXXL = SizedBox(width: xxl, height: xxl);

  // Horizontal gaps
  static const SizedBox gapHorizontalXS = SizedBox(width: xs);
  static const SizedBox gapHorizontalSM = SizedBox(width: sm);
  static const SizedBox gapHorizontalMD = SizedBox(width: md);
  static const SizedBox gapHorizontalLG = SizedBox(width: lg);
  static const SizedBox gapHorizontalXL = SizedBox(width: xl);

  // Vertical gaps
  static const SizedBox gapVerticalXS = SizedBox(height: xs);
  static const SizedBox gapVerticalSM = SizedBox(height: sm);
  static const SizedBox gapVerticalMD = SizedBox(height: md);
  static const SizedBox gapVerticalLG = SizedBox(height: lg);
  static const SizedBox gapVerticalXL = SizedBox(height: xl);

  // ===================================
  // 📏 COMMON MEASUREMENTS
  // ===================================
  
  /// Standard icon size
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;

  /// Avatar sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXL = 96.0;

  /// Convenience aliases for avatar sizes
  static const double avatarSmall = avatarSizeSmall;
  static const double avatarMedium = avatarSizeMedium;
  static const double avatarLarge = avatarSizeLarge;

  /// Button heights
  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 56.0;

  /// Input field height
  static const double inputHeight = 48.0;
  static const double inputHeightSmall = 40.0;

  /// AppBar height
  static const double appBarHeight = 64.0;

  /// Bottom navigation height
  static const double bottomNavHeight = 64.0;

  /// Card minimum height
  static const double cardMinHeight = 120.0;

  /// Divider thickness
  static const double dividerThickness = 1.0;
}

/// PlaySync Border Radius System
/// Consistent rounded corners for premium feel
class AppBorderRadius {
  AppBorderRadius._();

  // ===================================
  // 🔲 RADIUS VALUES
  // ===================================
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double full = 9999.0;

  // ===================================
  // 🔲 BORDER RADIUS OBJECTS
  // ===================================
  static const BorderRadius radiusNone = BorderRadius.zero;
  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius radiusXXXL = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));

  // ===================================
  // 🔲 COMPONENT-SPECIFIC RADIUS
  // ===================================
  
  /// Button radius (large, rounded)
  static const BorderRadius button = radiusXL;
  
  /// Card radius (medium-large)
  static const BorderRadius card = radiusLG;
  
  /// Modal/Dialog radius
  static const BorderRadius modal = radiusXXL;
  
  /// Input field radius
  static const BorderRadius input = radiusMD;
  
  /// Chip/Badge radius
  static const BorderRadius chip = radiusFull;
  
  /// Avatar radius (full for circle)
  static const BorderRadius avatar = radiusFull;

  // ===================================
  // 🔲 DIRECTIONAL RADIUS (Top only, etc.)
  // ===================================
  static const BorderRadius radiusTopMD = BorderRadius.only(
    topLeft: Radius.circular(md),
    topRight: Radius.circular(md),
  );

  static const BorderRadius radiusTopLG = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  static const BorderRadius radiusBottomMD = BorderRadius.only(
    bottomLeft: Radius.circular(md),
    bottomRight: Radius.circular(md),
  );

  static const BorderRadius radiusBottomLG = BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );

  // ===================================
  // 🔲 CONVENIENCE GETTERS
  // ===================================
  /// Convenience aliases for common usage
  static const BorderRadius small = radiusSM;
  static const BorderRadius medium = radiusMD;
  static const BorderRadius large = radiusLG;
  static const BorderRadius extraLarge = radiusXL;
  static const BorderRadius rounded = radiusFull;
}

/// Alias for AppBorderRadius for convenience
typedef AppRadius = AppBorderRadius;
