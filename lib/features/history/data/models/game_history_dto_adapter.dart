import 'package:hive/hive.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';

/// Hive Type Adapter for GameHistoryDto
/// 
/// Enables storing GameHistoryDto objects in Hive database
class GameHistoryDtoAdapter extends TypeAdapter<GameHistoryDto> {
  @override
  final int typeId = 4;

  @override
  GameHistoryDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return GameHistoryDto(
      id: fields[0] as String,
      game: fields[1] as GameDto,
      userId: fields[2] as String,
      joinedAt: fields[3] as String,
      leftAt: fields[4] as String?,
      completedAt: fields[5] as String?,
      pointsEarned: fields[6] as int,
      leftEarly: fields[7] as bool,
      status: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameHistoryDto obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.game)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.joinedAt)
      ..writeByte(4)
      ..write(obj.leftAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.pointsEarned)
      ..writeByte(7)
      ..write(obj.leftEarly)
      ..writeByte(8)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHistoryDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
