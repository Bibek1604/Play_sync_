/// Settings Feature - Clean Architecture
/// 
/// Structure:
/// ├── data/                    # Data Layer (future)
/// │   ├── datasources/         # Data sources
/// │   ├── models/              # Data models
/// │   └── repositories/        # Repository implementations
/// │
/// ├── domain/                  # Domain Layer (future)
/// │   ├── entities/            # Core business entities
/// │   ├── repositories/        # Repository contracts
/// │   └── usecases/            # Use cases
/// │
/// └── presentation/            # Presentation Layer
///     ├── pages/               # Full screen pages
///     ├── providers/           # State management
///     └── widgets/             # Reusable UI components
library;

export 'presentation/presentation.dart';
export 'domain/entities/app_settings.dart';
export 'data/settings_repository.dart';
export 'presentation/providers/theme_provider.dart';
export 'presentation/providers/language_provider.dart';
export 'presentation/providers/notification_prefs_provider.dart';
export 'presentation/pages/app_settings_page.dart';
export 'presentation/pages/about_page.dart';
export 'presentation/widgets/theme_preview_card.dart';
export 'presentation/widgets/accent_color_picker.dart';
