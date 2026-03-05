// Game feature barrel export
export 'domain/entities/game_entity.dart';
export 'domain/entities/invite_link_entity.dart';
export 'domain/entities/game_invitation_entity.dart';
export 'data/repositories/game_repository.dart';
// export 'data/services/game_event_listener.dart'; // Disabled - circular dependencies
export 'presentation/providers/game_notifier.dart';
export 'presentation/pages/game_page.dart';
export 'presentation/pages/available_games_page.dart';
export 'presentation/pages/online_games_page.dart';
export 'presentation/pages/offline_games_page.dart';
// Note: game_chat_page is now replaced by the new game_chat feature
export 'presentation/widgets/game_card.dart';
