# 🏗️ Clean Architecture Implementation Guide
## Flutter + Hive (Local DB) + API (Remote) + Riverpod

> **Based on:** Lost & Found Project  
> **Date:** January 2026

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Folder Structure](#folder-structure)
3. [Architecture Layers](#architecture-layers)
4. [Data Flow](#data-flow)
5. [Step-by-Step Implementation](#step-by-step-implementation)
6. [Code Templates](#code-templates)
7. [Dependencies](#dependencies)
8. [Checklist for New Features](#checklist-for-new-features)

---

## Overview

This project implements **Clean Architecture** with three distinct layers:

| Layer | Purpose | Contains |
|-------|---------|----------|
| **Presentation** | UI & State Management | Pages, Widgets, ViewModels, States |
| **Domain** | Business Logic | Entities, Use Cases, Repository Interfaces |
| **Data** | Data Access | Models, DataSources, Repository Implementations |

### Key Technologies Used:
- **State Management:** Riverpod (Notifier + Provider)
- **Local Database:** Hive
- **Remote API:** Dio
- **Error Handling:** dartz (Either type)
- **Equality:** equatable

---

## Folder Structure

```
lib/
├── main.dart                           # App entry point
├── app/
│   ├── app.dart                        # MaterialApp configuration
│   ├── routes/                         # App routing/navigation
│   └── theme/                          # App theming
│
├── core/                               # SHARED/CORE FUNCTIONALITY
│   ├── api/
│   │   ├── api_client.dart             # Dio HTTP client setup
│   │   └── api_endpoints.dart          # All API endpoint URLs
│   │
│   ├── constants/
│   │   └── hive_table_constant.dart    # Hive box names & type IDs
│   │
│   ├── error/
│   │   └── failures.dart               # Failure classes
│   │
│   ├── services/
│   │   ├── hive/
│   │   │   └── hive_service.dart       # Hive initialization & CRUD
│   │   ├── connectivity/               # Network connectivity check
│   │   ├── storage/                    # SharedPreferences/SecureStorage
│   │   └── sync/                       # Offline-first sync logic
│   │
│   ├── usecases/
│   │   └── app_usecases.dart           # Base usecase interfaces
│   │
│   ├── providers/                      # Global providers
│   ├── extensions/                     # Dart extensions
│   ├── utils/                          # Helper functions
│   └── widgets/                        # Reusable widgets
│
├── features/                           # FEATURE MODULES
│   ├── auth/
│   ├── item/
│   ├── category/
│   ├── batch/
│   └── [other_features]/
│
└── l10n/                               # Localization
```

### Feature Module Structure (e.g., `item/`)

```
features/item/
├── data/                               # DATA LAYER
│   ├── datasources/
│   │   ├── item_datasource.dart        # Abstract interface
│   │   ├── local/
│   │   │   └── item_local_datasource.dart    # Hive implementation
│   │   └── remote/
│   │       └── item_remote_datasource.dart   # API implementation
│   │
│   ├── models/
│   │   ├── item_hive_model.dart        # Hive model with annotations
│   │   └── item_hive_model.g.dart      # Generated adapter
│   │
│   ├── repositories/
│   │   └── item_repository.dart        # Repository implementation
│   │
│   └── schemas/                        # JSON schemas (optional)
│
├── domain/                             # DOMAIN LAYER
│   ├── entities/
│   │   └── item_entity.dart            # Pure Dart entity
│   │
│   ├── repositories/
│   │   └── item_repository.dart        # Abstract repository interface
│   │
│   └── usecases/
│       ├── create_item_usecase.dart
│       ├── get_all_items_usecase.dart
│       ├── get_item_by_id_usecase.dart
│       ├── update_item_usecase.dart
│       └── delete_item_usecase.dart
│
└── presentation/                       # PRESENTATION LAYER
    ├── pages/                          # Screen widgets
    ├── widgets/                        # Feature-specific widgets
    ├── state/
    │   └── item_state.dart             # Immutable state class
    ├── view_model/
    │   └── item_viewmodel.dart         # Riverpod Notifier
    └── providers/                      # Additional providers
```

---

## Architecture Layers

### Layer 1: Domain (Innermost - Pure Dart)

The **Domain Layer** is the core of the application. It contains:

#### 1.1 Entities
Pure Dart classes representing business objects.

```dart
// domain/entities/item_entity.dart
class ItemEntity extends Equatable {
  final String? itemId;
  final String itemName;
  final String? description;
  final ItemType type;
  final String location;
  final bool isClaimed;

  const ItemEntity({
    this.itemId,
    required this.itemName,
    this.description,
    required this.type,
    required this.location,
    this.isClaimed = false,
  });

  @override
  List<Object?> get props => [itemId, itemName, description, type, location, isClaimed];
}
```

#### 1.2 Repository Interfaces (Abstract)
Contracts that define what operations are available.

```dart
// domain/repositories/item_repository.dart
abstract interface class IItemRepository {
  Future<Either<Failure, List<ItemEntity>>> getAllItems();
  Future<Either<Failure, ItemEntity>> getItemById(String itemId);
  Future<Either<Failure, bool>> createItem(ItemEntity item);
  Future<Either<Failure, bool>> updateItem(ItemEntity item);
  Future<Either<Failure, bool>> deleteItem(String itemId);
}
```

#### 1.3 Use Cases
Single responsibility classes for each business operation.

```dart
// domain/usecases/get_all_items_usecase.dart
class GetAllItemsUsecase implements UsecaseWithoutParams<List<ItemEntity>> {
  final IItemRepository _itemRepository;

  GetAllItemsUsecase({required IItemRepository itemRepository})
    : _itemRepository = itemRepository;

  @override
  Future<Either<Failure, List<ItemEntity>>> call() {
    return _itemRepository.getAllItems();
  }
}
```

---

### Layer 2: Data (Outermost)

The **Data Layer** implements the domain interfaces.

#### 2.1 Models (Hive)
Data transfer objects with serialization.

```dart
// data/models/item_hive_model.dart
@HiveType(typeId: HiveTableConstant.itemTypeId)
class ItemHiveModel extends HiveObject {
  @HiveField(0)
  final String? itemId;

  @HiveField(1)
  final String itemName;

  // ... other fields

  // Convert TO Entity
  ItemEntity toEntity() {
    return ItemEntity(
      itemId: itemId,
      itemName: itemName,
      // ... map all fields
    );
  }

  // Convert FROM Entity
  factory ItemHiveModel.fromEntity(ItemEntity entity) {
    return ItemHiveModel(
      itemId: entity.itemId,
      itemName: entity.itemName,
      // ... map all fields
    );
  }
}
```

#### 2.2 DataSource Interface
Contract for data operations.

```dart
// data/datasources/item_datasource.dart
abstract interface class IItemDataSource {
  Future<List<ItemHiveModel>> getAllItems();
  Future<ItemHiveModel?> getItemById(String itemId);
  Future<bool> createItem(ItemHiveModel item);
  Future<bool> updateItem(ItemHiveModel item);
  Future<bool> deleteItem(String itemId);
}
```

#### 2.3 Local DataSource (Hive Implementation)

```dart
// data/datasources/local/item_local_datasource.dart
class ItemLocalDatasource implements IItemDataSource {
  final HiveService _hiveService;

  ItemLocalDatasource({required HiveService hiveService})
      : _hiveService = hiveService;

  @override
  Future<List<ItemHiveModel>> getAllItems() async {
    return _hiveService.getAllItems();
  }

  @override
  Future<bool> createItem(ItemHiveModel item) async {
    try {
      await _hiveService.createItem(item);
      return true;
    } catch (e) {
      return false;
    }
  }
  // ... other methods
}
```

#### 2.4 Repository Implementation

```dart
// data/repositories/item_repository.dart
class ItemRepository implements IItemRepository {
  final IItemDataSource _itemDataSource;

  ItemRepository({required IItemDataSource itemDatasource})
      : _itemDataSource = itemDatasource;

  @override
  Future<Either<Failure, List<ItemEntity>>> getAllItems() async {
    try {
      final models = await _itemDataSource.getAllItems();
      final entities = ItemHiveModel.toEntityList(models);
      return Right(entities);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
  // ... other methods
}
```

---

### Layer 3: Presentation

The **Presentation Layer** handles UI and state.

#### 3.1 State Class

```dart
// presentation/state/item_state.dart
enum ItemStatus { initial, loading, loaded, error, created, updated, deleted }

class ItemState extends Equatable {
  final ItemStatus status;
  final List<ItemEntity> items;
  final ItemEntity? selectedItem;
  final String? errorMessage;

  const ItemState({
    this.status = ItemStatus.initial,
    this.items = const [],
    this.selectedItem,
    this.errorMessage,
  });

  ItemState copyWith({...}) {
    return ItemState(...);
  }

  @override
  List<Object?> get props => [status, items, selectedItem, errorMessage];
}
```

#### 3.2 ViewModel (Notifier)

```dart
// presentation/view_model/item_viewmodel.dart
class ItemViewModel extends Notifier<ItemState> {
  late final GetAllItemsUsecase _getAllItemsUsecase;
  // ... other usecases

  @override
  ItemState build() {
    _getAllItemsUsecase = ref.read(getAllItemsUsecaseProvider);
    // ... initialize other usecases
    return const ItemState();
  }

  Future<void> getAllItems() async {
    state = state.copyWith(status: ItemStatus.loading);

    final result = await _getAllItemsUsecase();

    result.fold(
      (failure) => state = state.copyWith(
        status: ItemStatus.error,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        status: ItemStatus.loaded,
        items: items,
      ),
    );
  }
}
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERACTION                            │
│                              (UI Page)                              │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ triggers
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           VIEW MODEL                                │
│                     (ItemViewModel - Notifier)                      │
│                                                                     │
│   • Calls UseCase                                                   │
│   • Updates State based on result                                   │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ calls
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            USE CASE                                 │
│                      (GetAllItemsUsecase)                           │
│                                                                     │
│   • Single responsibility                                           │
│   • Returns Either<Failure, Success>                                │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ calls
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    REPOSITORY (Abstract Interface)                  │
│                         (IItemRepository)                           │
│                                                                     │
│   • Defined in Domain layer                                         │
│   • Implemented in Data layer                                       │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ implemented by
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  REPOSITORY (Implementation)                        │
│                        (ItemRepository)                             │
│                                                                     │
│   • Converts Model ↔ Entity                                         │
│   • Wraps in Either<Failure, Success>                               │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ uses
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    DATA SOURCE (Interface)                          │
│                        (IItemDataSource)                            │
└───────────────┬─────────────────────────────────┬───────────────────┘
                │                                 │
                ▼                                 ▼
┌───────────────────────────┐     ┌───────────────────────────────────┐
│    LOCAL DATASOURCE       │     │      REMOTE DATASOURCE            │
│  (ItemLocalDatasource)    │     │   (ItemRemoteDatasource)          │
│                           │     │                                   │
│   Uses HiveService        │     │   Uses ApiClient (Dio)            │
└───────────────┬───────────┘     └───────────────┬───────────────────┘
                │                                 │
                ▼                                 ▼
┌───────────────────────────┐     ┌───────────────────────────────────┐
│      HIVE DATABASE        │     │         REST API                  │
│    (Local Storage)        │     │       (Backend)                   │
└───────────────────────────┘     └───────────────────────────────────┘
```

---

## Step-by-Step Implementation

### How to Add a New Feature (e.g., "Product")

Follow these steps in order:

---

### Step 1: Create Core Dependencies (One-time setup)

#### 1.1 Hive Constants

```dart
// lib/core/constants/hive_table_constant.dart
class HiveTableConstant {
  HiveTableConstant._();

  static const String dbName = "your_app_db";

  // Type IDs (must be unique 0-223)
  static const int productTypeId = 5;  // Add new type ID
  
  // Table names
  static const String productTable = "product_table";
}
```

#### 1.2 Base Use Case Interfaces

```dart
// lib/core/usecases/app_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:your_app/core/error/failures.dart';

abstract interface class UsecaseWithParams<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

abstract interface class UsecaseWithoutParams<SuccessType> {
  Future<Either<Failure, SuccessType>> call();
}
```

#### 1.3 Failure Classes

```dart
// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class LocalDatabaseFailure extends Failure {
  const LocalDatabaseFailure({String message = "Local Database Failure"})
    : super(message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure({String message = "API Failure", this.statusCode})
    : super(message);
}
```

---

### Step 2: Domain Layer

#### 2.1 Create Entity

```dart
// lib/features/product/domain/entities/product_entity.dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String? productId;
  final String name;
  final double price;
  final String? description;
  final bool isAvailable;

  const ProductEntity({
    this.productId,
    required this.name,
    required this.price,
    this.description,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [productId, name, price, description, isAvailable];
}
```

#### 2.2 Create Repository Interface

```dart
// lib/features/product/domain/repositories/product_repository.dart
import 'package:dartz/dartz.dart';
import 'package:your_app/core/error/failures.dart';
import 'package:your_app/features/product/domain/entities/product_entity.dart';

abstract interface class IProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getAllProducts();
  Future<Either<Failure, ProductEntity>> getProductById(String productId);
  Future<Either<Failure, bool>> createProduct(ProductEntity product);
  Future<Either<Failure, bool>> updateProduct(ProductEntity product);
  Future<Either<Failure, bool>> deleteProduct(String productId);
}
```

#### 2.3 Create Use Cases

```dart
// lib/features/product/domain/usecases/get_all_products_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/core/error/failures.dart';
import 'package:your_app/core/usecases/app_usecases.dart';
import 'package:your_app/features/product/data/repositories/product_repository.dart';
import 'package:your_app/features/product/domain/entities/product_entity.dart';
import 'package:your_app/features/product/domain/repositories/product_repository.dart';

final getAllProductsUsecaseProvider = Provider<GetAllProductsUsecase>((ref) {
  final repository = ref.read(productRepositoryProvider);
  return GetAllProductsUsecase(repository: repository);
});

class GetAllProductsUsecase implements UsecaseWithoutParams<List<ProductEntity>> {
  final IProductRepository _repository;

  GetAllProductsUsecase({required IProductRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<ProductEntity>>> call() {
    return _repository.getAllProducts();
  }
}
```

---

### Step 3: Data Layer

#### 3.1 Create Hive Model

```dart
// lib/features/product/data/models/product_hive_model.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:your_app/core/constants/hive_table_constant.dart';
import 'package:your_app/features/product/domain/entities/product_entity.dart';

part 'product_hive_model.g.dart';

@HiveType(typeId: HiveTableConstant.productTypeId)
class ProductHiveModel extends HiveObject {
  @HiveField(0)
  final String? productId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final bool isAvailable;

  ProductHiveModel({
    String? productId,
    required this.name,
    required this.price,
    this.description,
    bool? isAvailable,
  })  : productId = productId ?? const Uuid().v4(),
        isAvailable = isAvailable ?? true;

  // Convert to Entity
  ProductEntity toEntity() {
    return ProductEntity(
      productId: productId,
      name: name,
      price: price,
      description: description,
      isAvailable: isAvailable,
    );
  }

  // Convert from Entity
  factory ProductHiveModel.fromEntity(ProductEntity entity) {
    return ProductHiveModel(
      productId: entity.productId,
      name: entity.name,
      price: entity.price,
      description: entity.description,
      isAvailable: entity.isAvailable,
    );
  }

  // Convert list to entities
  static List<ProductEntity> toEntityList(List<ProductHiveModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
```

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3.2 Create DataSource Interface & Local Implementation

```dart
// lib/features/product/data/datasources/product_datasource.dart
import 'package:your_app/features/product/data/models/product_hive_model.dart';

abstract interface class IProductDataSource {
  Future<List<ProductHiveModel>> getAllProducts();
  Future<ProductHiveModel?> getProductById(String productId);
  Future<bool> createProduct(ProductHiveModel product);
  Future<bool> updateProduct(ProductHiveModel product);
  Future<bool> deleteProduct(String productId);
}
```

---

### Step 4: Presentation Layer

#### 4.1 Create State

```dart
// lib/features/product/presentation/state/product_state.dart
import 'package:equatable/equatable.dart';
import 'package:your_app/features/product/domain/entities/product_entity.dart';

enum ProductStatus { initial, loading, loaded, error, created, updated, deleted }

class ProductState extends Equatable {
  final ProductStatus status;
  final List<ProductEntity> products;
  final ProductEntity? selectedProduct;
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.selectedProduct,
    this.errorMessage,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<ProductEntity>? products,
    ProductEntity? selectedProduct,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, selectedProduct, errorMessage];
}
```

#### 4.2 Create ViewModel

```dart
// lib/features/product/presentation/view_model/product_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_app/features/product/domain/entities/product_entity.dart';
import 'package:your_app/features/product/domain/usecases/get_all_products_usecase.dart';
import 'package:your_app/features/product/presentation/state/product_state.dart';

final productViewModelProvider = NotifierProvider<ProductViewModel, ProductState>(
  ProductViewModel.new,
);

class ProductViewModel extends Notifier<ProductState> {
  late final GetAllProductsUsecase _getAllProductsUsecase;

  @override
  ProductState build() {
    _getAllProductsUsecase = ref.read(getAllProductsUsecaseProvider);
    return const ProductState();
  }

  Future<void> getAllProducts() async {
    state = state.copyWith(status: ProductStatus.loading);
    final result = await _getAllProductsUsecase();

    result.fold(
      (failure) => state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: failure.message,
      ),
      (products) => state = state.copyWith(
        status: ProductStatus.loaded,
        products: products,
      ),
    );
  }
}
```

---

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Functional Programming (Either type for error handling)
  dartz: ^0.10.1
  
  # Local Database
  hive: ^2.2.3
  path_provider: ^2.1.1
  
  # API Client
  dio: ^5.3.3
  
  # Utilities
  equatable: ^2.0.5
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Hive code generation
  hive_generator: ^2.0.1
  build_runner: ^2.4.6
```

---

## Checklist for New Features

Use this checklist when adding a new feature:

### Domain Layer
- [ ] Create Entity class (`domain/entities/[feature]_entity.dart`)
- [ ] Create Repository interface (`domain/repositories/[feature]_repository.dart`)
- [ ] Create Use Cases

### Data Layer
- [ ] Add Hive type ID to `HiveTableConstant`
- [ ] Create Hive Model (`data/models/[feature]_hive_model.dart`)
- [ ] Run `flutter pub run build_runner build`
- [ ] Create DataSource interface & implementation
- [ ] Create Repository implementation

### Presentation Layer
- [ ] Create State class (`presentation/state/[feature]_state.dart`)
- [ ] Create ViewModel (`presentation/view_model/[feature]_viewmodel.dart`)
- [ ] Create UI pages (`presentation/pages/`)

---

## Quick Reference: Provider Chain

```
UI (ConsumerWidget)
    │
    ▼ watches
productViewModelProvider (NotifierProvider)
    │
    ▼ reads
getAllProductsUsecaseProvider (Provider)
    │
    ▼ reads
productRepositoryProvider (Provider)
    │
    ▼ reads
productLocalDatasourceProvider (Provider)
    │
    ▼ reads
hiveServiceProvider (Provider)
```

---

## Key Principles

1. **Domain is PURE** - No Flutter/external dependencies
2. **Dependency flows inward** - Data → Domain ← Presentation
3. **Use Either<Failure, Success>** - For error handling
4. **Model ↔ Entity conversion** - Models in Data, Entities in Domain
5. **Single Responsibility** - Each UseCase does ONE thing
6. **Dependency Injection** - Use Riverpod providers everywhere

---

## Author Notes

This architecture provides:
- ✅ **Testability** - Each layer can be tested independently
- ✅ **Maintainability** - Clear separation of concerns
- ✅ **Scalability** - Easy to add new features
- ✅ **Offline-first** - Hive for local storage
- ✅ **Flexibility** - Easy to swap data sources (local ↔ remote)

---

*Document generated from Lost & Found project analysis - January 2026*
