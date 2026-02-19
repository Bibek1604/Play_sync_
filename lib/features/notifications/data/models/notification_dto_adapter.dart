import 'package:hive/hive.dart';
import 'package:play_sync_new/features/notifications/data/models/notification_dto.dart';

class NotificationDtoAdapter extends TypeAdapter<NotificationDto> {
  @override
  final int typeId = 7;

  @override
  NotificationDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return NotificationDto(
      id: fields[0] as String,
      user: fields[1] as String,
      type: fields[2] as String,
      title: fields[3] as String,
      message: fields[4] as String,
      data: Map<String, dynamic>.from(fields[5] as Map),
      link: fields[6] as String?,
      read: fields[7] as bool,
      createdAt: fields[8] as String,
      updatedAt: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationDto obj) {
    writer
      ..writeByte(10) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.user)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.data)
      ..writeByte(6)
      ..write(obj.link)
      ..writeByte(7)
      ..write(obj.read)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
