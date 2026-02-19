import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';

/// Shimmer Loading Effect
/// 
/// Skeleton loader matching web version
class ShimmerLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? AppColors.shimmerBaseDark
          : AppColors.shimmerBaseLight,
      highlightColor: isDark
          ? AppColors.shimmerHighlightDark
          : AppColors.shimmerHighlightLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppBorderRadius.card,
        ),
      ),
    );
  }
}

/// Card Shimmer (for loading cards)
class CardShimmer extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const CardShimmer({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(
            height: height ?? 120,
            borderRadius: AppBorderRadius.card,
          ),
        ],
      ),
    );
  }
}

/// List Item Shimmer
class ListItemShimmer extends StatelessWidget {
  final bool hasAvatar;
  final EdgeInsets? padding;

  const ListItemShimmer({
    super.key,
    this.hasAvatar = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.paddingMD,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar) ...[
            const ShimmerLoader(
              width: AppSpacing.avatarMedium,
              height: AppSpacing.avatarMedium,
              borderRadius: BorderRadius.all(Radius.circular(100)),
            ),
            AppSpacing.gapHorizontalMD,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(
                  height: 16,
                  width: double.infinity,
                  borderRadius: AppBorderRadius.input,
                ),
                AppSpacing.gapVerticalSM,
                ShimmerLoader(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.6,
                  borderRadius: AppBorderRadius.input,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Player Card Shimmer (for game lobby)
class PlayerCardShimmer extends StatelessWidget {
  final EdgeInsets? margin;

  const PlayerCardShimmer({
    super.key,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: AppSpacing.paddingMD,
      child: Row(
        children: [
          const ShimmerLoader(
            width: AppSpacing.avatarMedium,
            height: AppSpacing.avatarMedium,
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.4,
                  borderRadius: AppBorderRadius.input,
                ),
                AppSpacing.gapVerticalSM,
                Row(
                  children: [
                    ShimmerLoader(
                      height: 12,
                      width: 60,
                      borderRadius: AppBorderRadius.chip,
                    ),
                    AppSpacing.gapHorizontalSM,
                    ShimmerLoader(
                      height: 12,
                      width: 80,
                      borderRadius: AppBorderRadius.chip,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats Shimmer (for dashboard stats)
class StatsShimmer extends StatelessWidget {
  const StatsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(
            height: 40,
            width: 120,
            borderRadius: AppBorderRadius.card,
          ),
          AppSpacing.gapVerticalSM,
          ShimmerLoader(
            height: 20,
            width: 160,
            borderRadius: AppBorderRadius.input,
          ),
        ],
      ),
    );
  }
}
