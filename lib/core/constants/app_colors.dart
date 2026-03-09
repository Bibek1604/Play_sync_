import "package:flutter/material.dart";

class AppColors {
  AppColors._();
static const Color primary       = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryDark   = Color(0xFF1E3070);
  static const Color primaryLight  = Color(0xFFDBEAFE);
  static const Color primaryAlt    = Color(0xFF2563EB);
  static const Color secondary     = Color(0xFF3B82F6); 
  static const Color secondaryLight = Color(0xFFEFF6FF);
  static const Color accent        = Color(0xFF10B981); 
static const Color background    = Color(0xFFF8FAFC); 
  static const Color surface       = Colors.white;
  static const Color surfaceLight  = Color(0xFFF3F4F6);
  static const Color surfaceMuted  = Color(0xFFE5E7EB);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color border        = Color(0xFFE2E8F0); 
  static const Color borderSubtle  = Color(0xFFE5E7EB);
  static const Color textPrimary   = Color(0xFF0F172A); 
  static const Color textSecondary = Color(0xFF475569); 
  static const Color textTertiary  = Color(0xFF94A3B8); 
  static const Color textOnPrimary = Colors.white;
static const Color backgroundDark = Color(0xFF0F172A); 
  static const Color surfaceDark    = Color(0xFF1E293B); 
  static const Color cardDark       = Color(0xFF1E293B);
  static const Color borderDark     = Color(0xFF334155); 
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color surfaceVariantDark = Color(0xFF1E293B);
static const Color success      = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark  = Color(0xFF047857);
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFEE2E2);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info         = Color(0xFF3B82F6);
static const Color rankGold   = Color(0xFFF59E0B);
  static const Color rankSilver = Color(0xFF94A3B8);
  static const Color rankBronze = Color(0xFFB45309);
static const Color chatBubbleOwn = Color(0xFF0284C7); // Signature Blue

  static Color primaryWithOpacity(double o) => primary.withOpacity(o);
  static Color withOpacity(Color c, double o) => c.withOpacity(o);
}
