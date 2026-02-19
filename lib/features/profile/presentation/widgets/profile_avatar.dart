import 'package:flutter/material.dart';

/// Circular avatar with an automatic initialled fallback when imageUrl is null.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 28,
    this.backgroundColor,
    this.onTap,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;

    Widget avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(imageUrl!),
            backgroundColor: bg,
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.65,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
