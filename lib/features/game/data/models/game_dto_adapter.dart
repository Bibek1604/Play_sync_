import 'package:hive/hive.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';

/// Hive Type Adapter for GameDto
/// 
/// Enables storing GameDto objects in Hive database
class GameDtoAdapter extends TypeAdapter<GameDto> {
  @override
  final int typeId = 1;

  @override
  GameDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return GameDto(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      location: fields[3] as String?,
      tags: (fields[4] as List).cast<String>(),
      imageUrl: fields[5] as String?,
      imagePublicId: fields[6] as String?,
      maxPlayers: fields[7] as int,
      minPlayers: fields[8] as int,
      currentPlayers: fields[9] as int,
      category: fields[10] as String,
      status: fields[11] as String,
      creatorId: fields[12],
      participants: (fields[13] as List).cast<ParticipantDto>(),
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[14] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(fields[15] as int),
      endedAt: fields[16] != null ? DateTime.fromMillisecondsSinceEpoch(fields[16] as int) : null,
      cancelledAt: fields[17] != null ? DateTime.fromMillisecondsSinceEpoch(fields[17] as int) : null,
      completedAt: fields[18] != null ? DateTime.fromMillisecondsSinceEpoch(fields[18] as int) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[19] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[20] as int),
      metadata: fields[21] as Map<String, dynamic>?,
      latitude: fields[22] as double?,
      longitude: fields[23] as double?,
      maxDistance: fields[24] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, GameDto obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.imagePublicId)
      ..writeByte(7)
      ..write(obj.maxPlayers)
      ..writeByte(8)
      ..write(obj.minPlayers)
      ..writeByte(9)
      ..write(obj.currentPlayers)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.creatorId)
      ..writeByte(13)
      ..write(obj.participants)
      ..writeByte(14)
      ..write(obj.startTime.millisecondsSinceEpoch)
      ..writeByte(15)
      ..write(obj.endTime.millisecondsSinceEpoch)
      ..writeByte(16)
      ..write(obj.endedAt?.millisecondsSinceEpoch)
      ..writeByte(17)
      ..write(obj.cancelledAt?.millisecondsSinceEpoch)
      ..writeByte(18)
      ..write(obj.completedAt?.millisecondsSinceEpoch)
      ..writeByte(19)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(20)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      ..writeByte(21)
      ..write(obj.metadata)
      ..writeByte(22)
      ..write(obj.latitude)
      ..writeByte(23)
      ..write(obj.longitude)
      ..writeByte(24)
      ..write(obj.maxDistance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive Type Adapter for ParticipantDto
/// 
/// Enables storing ParticipantDto objects in Hive database
class ParticipantDtoAdapter extends TypeAdapter<ParticipantDto> {
  @override
  final int typeId = 11;

  @override
  ParticipantDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return ParticipantDto(
      userId: fields[0] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      leftAt: fields[2] != null ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int) : null,
      status: fields[3] as String,
      activityLogs: (fields[4] as List).cast<ActivityLogDto>(),
    );
  }

  @override
  void write(BinaryWriter writer, ParticipantDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.joinedAt.millisecondsSinceEpoch)
      ..writeByte(2)
      ..write(obj.leftAt?.millisecondsSinceEpoch)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.activityLogs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive Type Adapter for ActivityLogDto
/// 
/// Enables storing ActivityLogDto objects in Hive database
class ActivityLogDtoAdapter extends TypeAdapter<ActivityLogDto> {
  @override
  final int typeId = 12;

  @override
  ActivityLogDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return ActivityLogDto(
      status: fields[0] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLogDto obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.timestamp.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
