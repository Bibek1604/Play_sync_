import 'package:equatable/equatable.dart';

/// Represents an achievement badge earned by the user.
class ProfileBadge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconCode; // icon codepoint as hex string
  final DateTime earnedAt;
  final BadgeRarity rarity;

  const ProfileBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCode,
    required this.earnedAt,
    this.rarity = BadgeRarity.common,
  });

  @override
  List<Object?> get props => [id, title, rarity, earnedAt];
}

enum BadgeRarity { common, rare, epic, legendary }

extension BadgeRarityX on BadgeRarity {
  String get label {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  int get sortOrder {
    switch (this) {
      case BadgeRarity.common:
        return 0;
      case BadgeRarity.rare:
        return 1;
      case BadgeRarity.epic:
        return 2;
      case BadgeRarity.legendary:
        return 3;
    }
  }
}
