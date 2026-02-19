import 'package:hive/hive.dart';
import 'package:play_sync_new/features/game/data/models/chat_message_dto.dart';

/// Hive Type Adapter for ChatMessageDto
/// 
/// TypeId: 10
class ChatMessageDtoAdapter extends TypeAdapter<ChatMessageDto> {
  @override
  final int typeId = 10;

  @override
  ChatMessageDto read(BinaryReader reader) {
    return ChatMessageDto(
      id: reader.readString(),
      gameId: reader.readString(),
      senderId: reader.readString(),
      senderName: reader.readString(),
      message: reader.readString(),
      timestamp: reader.readString(),
      type: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageDto obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.gameId);
    writer.writeString(obj.senderId);
    writer.writeString(obj.senderName);
    writer.writeString(obj.message);
    writer.writeString(obj.timestamp);
    writer.writeString(obj.type);
  }
}
