import 'package:flutter/material.dart';

/// Overlapping stack of up to 4 user avatars with an overflow counter.
/// Great for showing players in a game card header area.
///
/// Example: [🟢][🔵][🟠] +3
class AvatarStack extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String> names;
  final double radius;
  final int maxShown;

  const AvatarStack({
    super.key,
    required this.imageUrls,
    required this.names,
    this.radius = 18,
    this.maxShown = 4,
  });

  @override
  Widget build(BuildContext context) {
    final shown = imageUrls.take(maxShown).toList();
    final overflow = imageUrls.length - shown.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: shown.length * (radius * 1.4) + radius * 0.4,
          height: radius * 2,
          child: Stack(
            children: [
              for (int i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (radius * 1.4),
                  child: _Avatar(
                    url: shown[i],
                    name: i < names.length ? names[i] : '?',
                    radius: radius,
                    borderColor: Theme.of(context).cardColor,
                  ),
                ),
            ],
          ),
        ),
        if (overflow > 0) ...[
          const SizedBox(width: 4),
          Text(
            '+$overflow',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  final Color borderColor;

  const _Avatar({
    required this.url,
    required this.name,
    required this.radius,
    required this.borderColor,
  });

  String get _initial =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: url != null && url!.isNotEmpty
          ? CircleAvatar(radius: radius, backgroundImage: NetworkImage(url!))
          : CircleAvatar(
              radius: radius,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(_initial,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.65,
                      fontWeight: FontWeight.bold)),
            ),
    );
  }
}
