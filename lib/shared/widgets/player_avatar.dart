import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';

/// Player Avatar with Online Indicator
/// 
/// Displays player avatar with optional online status dot
class PlayerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppSpacing.avatarMedium,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null
            ? AppColors.primaryGradient
            : null,
        border: Border.all(
          color: isDark
              ? AppColors.borderDefaultDark
              : AppColors.borderDefaultLight,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );

    // Add online status indicator
    if (showOnlineStatus) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? AppColors.statusSuccess
                    : AppColors.slate400,
                border: Border.all(
                  color: isDark
                      ? AppColors.backgroundPrimaryDark
                      : AppColors.backgroundPrimaryLight,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitials() {
    final String initials = _getInitials();

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final List<String> nameParts = name!.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  }
}

/// Avatar Group (for showing multiple players)
class AvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final double size;
  final int maxVisible;

  const AvatarGroup({
    super.key,
    required this.imageUrls,
    required this.names,
    this.size = AppSpacing.avatarSmall,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    final int visibleCount = imageUrls.length > maxVisible 
        ? maxVisible 
        : imageUrls.length;
    final int remaining = imageUrls.length - visibleCount;

    return SizedBox(
      height: size,
      child: Stack(
        children: [
          // Visible avatars
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * (size * 0.7),
              child: PlayerAvatar(
                imageUrl: imageUrls[i],
                name: names[i],
                size: size,
              ),
            ),

          // Remaining count
          if (remaining > 0)
            Positioned(
              left: visibleCount * (size * 0.7),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.slate700,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
