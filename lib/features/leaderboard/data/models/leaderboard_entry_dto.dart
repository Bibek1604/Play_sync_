import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardEntryDto {
  final UserDto userId;
  final int points;
  final int rank;

  LeaderboardEntryDto({
    required this.userId,
    required this.points,
    required this.rank,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) {
    // Handle nested userId object from backend
    final userIdData = json['userId'] ?? json['user_id'] ?? {};
    
    return LeaderboardEntryDto(
      userId: UserDto.fromJson(userIdData is Map<String, dynamic> ? userIdData : {}),
      points: json['points'] ?? json['totalPoints'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  LeaderboardEntry toEntity() {
    return LeaderboardEntry(
      userId: userId.id,
      userName: userId.fullName,
      userAvatar: userId.avatar,
      points: points,
      rank: rank,
    );
  }
}

class UserDto {
  final String id;
  final String fullName;
  final String? avatar;

  UserDto({
    required this.id,
    required this.fullName,
    this.avatar,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // Extract name — try every field name the backend might use
    final rawName = (json['fullName'] ?? json['full_name'] ?? json['name'] ??
            json['username'] ?? json['userName'])
        ?.toString()
        .trim();

    // Fall back to email prefix, then generic label
    final email = (json['email'] ?? '').toString();
    final resolvedName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : email.contains('@')
            ? email.split('@').first
            : 'Player';

    return UserDto(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: resolvedName,
      avatar: (json['avatar'] ?? json['profilePicture'] ?? json['profile_picture'])
          ?.toString(),
    );
  }
}
