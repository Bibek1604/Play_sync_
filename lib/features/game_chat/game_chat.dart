/// Game Chat Feature — Public API
///
/// Import this file to access the chat room page and providers.
library;

// ── Domain ──────────────────────────────────────────────────────────────────
export 'domain/entities/message_entity.dart';
export 'domain/repositories/game_chat_repository.dart';

// ── Data ────────────────────────────────────────────────────────────────────
export 'data/models/message_model.dart';
export 'data/datasources/game_chat_remote_datasource.dart';
export 'data/repositories/game_chat_repository_impl.dart';

// ── Presentation ────────────────────────────────────────────────────────────
export 'presentation/state/game_chat_state.dart';
export 'presentation/notifiers/game_chat_notifier.dart';
export 'presentation/pages/game_chat_room_page.dart';
