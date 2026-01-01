// Auth Feature - Clean Architecture
// 
// Structure:
// ├── data/                    # Data Layer
// │   ├── datasources/         # Data sources (local/remote)
// │   │   ├── local/           # Hive local storage
// │   │   └── remote/          # API calls (future)
// │   ├── models/              # Data models with Hive adapters
// │   └── repositories/        # Repository implementations
// │
// ├── domain/                  # Domain Layer (Business Logic)
// │   ├── entities/            # Core business entities
// │   ├── repositories/        # Repository contracts (abstract)
// │   └── usecases/            # Use cases (single responsibility)
// │
// └── presentation/            # Presentation Layer
//     ├── pages/               # Full screen pages
//     ├── providers/           # State management (Riverpod)
//     └── widgets/             # Reusable UI components

export 'data/data.dart';
export 'domain/domain.dart';
export 'presentation/presentation.dart';
