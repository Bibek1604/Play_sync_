import 'package:hive/hive.dart';
import 'package:play_sync_new/features/leaderboard/data/models/leaderboard_entry_dto.dart';

/// Hive Type Adapter for UserDto
/// 
/// Enables storing UserDto objects in Hive database
class UserDtoAdapter extends TypeAdapter<UserDto> {
  @override
  final int typeId = 5;

  @override
  UserDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return UserDto(
      id: fields[0] as String,
      fullName: fields[1] as String,
      avatar: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.avatar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive Type Adapter for LeaderboardEntryDto
/// 
/// Enables storing LeaderboardEntryDto objects in Hive database
class LeaderboardEntryDtoAdapter extends TypeAdapter<LeaderboardEntryDto> {
  @override
  final int typeId = 6;

  @override
  LeaderboardEntryDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return LeaderboardEntryDto(
      userId: fields[0] as UserDto,
      points: fields[1] as int,
      rank: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderboardEntryDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.rank);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
