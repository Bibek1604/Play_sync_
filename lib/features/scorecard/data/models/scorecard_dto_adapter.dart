import 'package:hive/hive.dart';
import 'package:play_sync_new/features/scorecard/data/models/scorecard_dto.dart';

class BreakdownDtoAdapter extends TypeAdapter<BreakdownDto> {
  @override
  final int typeId = 8;

  @override
  BreakdownDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return BreakdownDto(
      pointsFromJoins: fields[0] as int,
      pointsFromTime: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BreakdownDto obj) {
    writer
      ..writeByte(2) // number of fields
      ..writeByte(0)
      ..write(obj.pointsFromJoins)
      ..writeByte(1)
      ..write(obj.pointsFromTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakdownDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScorecardDtoAdapter extends TypeAdapter<ScorecardDto> {
  @override
  final int typeId = 9;

  @override
  ScorecardDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return ScorecardDto(
      userId: fields[0] as String?,
      points: fields[1] as int,
      totalPoints: fields[2] as int?,
      rank: fields[3] as int,
      gamesJoined: fields[4] as int?,
      gamesPlayed: fields[5] as int?,
      totalMinutesPlayed: fields[6] as int?,
      updatedAt: fields[7] as String?,
      breakdown: fields[8] as BreakdownDto?,
    );
  }

  @override
  void write(BinaryWriter writer, ScorecardDto obj) {
    writer
      ..writeByte(9) // number of fields
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.totalPoints)
      ..writeByte(3)
      ..write(obj.rank)
      ..writeByte(4)
      ..write(obj.gamesJoined)
      ..writeByte(5)
      ..write(obj.gamesPlayed)
      ..writeByte(6)
      ..write(obj.totalMinutesPlayed)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.breakdown);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScorecardDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
