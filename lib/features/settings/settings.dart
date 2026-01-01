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
