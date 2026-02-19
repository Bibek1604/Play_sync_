# Authentication & Profile Flow in Clean Architecture

This document outlines the detailed flow of the **Authentication** and **Profile** features within the `play_sync_new` application, adhering to Clean Architecture principles.

## 🏗️ Architectural Layers Overview

The application is structured into three distinct layers to ensure separation of concerns, testability, and maintainability:

1.  **Domain Layer (Inner Layer)**
    *   **Responsibility**: The "Brain". Contains pure business logic, entities, and repository interfaces.
    *   **Dependencies**: None. It knows *nothing* about Flutter, APIs, or Databases.
    
2.  **Data Layer (Middle Layer)**
    *   **Responsibility**: The "Worker". Handles data retrieval and storage. Implements Domain interfaces.
    *   **Dependencies**: APIs, Local Storage (Hive, Secure Storage), 3rd party libraries.

3.  **Presentation Layer (Outer Layer)**
    *   **Responsibility**: The "Face". Handles UI rendering and State Management (Riverpod).
    *   **Dependencies**: Domain Layer, Flutter Framework.

---

## 🔐 Authentication Flow

The Authentication flow manages user login, registration, and session maintenance.

### 1. Presentation Layer (UI Trigger)
*   **User Action**: The user enters their credentials (email/password) and initiates a login or registration.
*   **Component**: `AuthViewModel` (Riverpod Provider).
*   **Process**:
    1.  The UI calls a method on the `AuthViewModel` (e.g., `login()`).
    2.  The ViewModel sets the state to `loading`.
    3.  It invokes the corresponding **UseCase**.

```dart
// features/auth/presentation/view_model/auth_viewmodel.dart
Future<void> login(String email, String password) async {
  state = state.copyWith(status: AuthStatus.loading);
  final result = await _loginUsecase.call(
    LoginParams(email: email, password: password),
  );
  // Handle result (success/failure)
}
```

### 2. Domain Layer (Business Logic)
*   **Component**: `LoginUsecase`.
*   **Process**:
    1.  Receives the `LoginParams` from the ViewModel.
    2.  Executes the business logic (which in this case is delegating the call to the repository).
    3.  Returns an `Either<Failure, AuthEntity>` to handling success or error.

```dart
// features/auth/domain/usecases/login_usecase.dart
class LoginUsecase implements UsecaseWithParams<AuthEntity, LoginParams> {
  final IAuthRepository _repository;

  @override
  Future<Either<Failure, AuthEntity>> call(LoginParams params) {
    return _repository.login(email: params.email, password: params.password);
  }
}
```

### 3. Data Layer (Implementation)
*   **Component**: `AuthRepositoryImpl`.
*   **Process**:
    1.  **API Call**: Calls the `AuthRemoteDataSource` to hit the backend API.
    2.  **Token Management**: Upon success, it securely authenticates the session by saving tokens locally.
        *   Uses `FlutterSecureStorage` for `access_token` and `refresh_token`.
    3.  **Data Conversion**: Converts the raw data model (`AuthModel`) into a clean domain entity (`AuthEntity`).

```dart
// features/auth/data/repositories/auth_repository_impl.dart
@override
Future<Either<Failure, AuthEntity>> login({required String email, required String password}) async {
  try {
    final response = await _remoteDataSource.login(email: email, password: password);
    
    // Save tokens securely
    await _secureStorage.write(key: 'access_token', value: response.token);
    
    return Right(response.toEntity());
  } catch (e) {
    return Left(AuthFailure(message: e.toString()));
  }
}
```

---

## 👤 Profile Flow (with Caching Strategy)

The Profile flow demonstrates a more complex interaction pattern, potentially using caching to improve user experience.

### 1. Presentation Layer
*   **User Action**: User navigates to the Profile screen.
*   **Component**: `ProfileViewModel` (or similar).
*   **Process**: Calls `getProfile()` to fetch user details.

### 2. Domain Layer
*   **Component**: `GetProfileUsecase`.
*   **Process**: Requests the user profile from the `IProfileRepository`.

```dart
// features/profile/domain/usecases/get_profile_usecase.dart
class GetProfileUsecase {
  final IProfileRepository _repository;

  Future<Either<Failure, ProfileEntity>> call() async {
    return await _repository.getProfile();
  }
}
```

### 3. Data Layer (Smart Repository)
*   **Component**: `ProfileRepositoryImpl`.
*   **Strategy**: **Cache-First / Smart Caching**.
*   **Process**:
    1.  **Check Local**: Attempts to retrieve the profile from `ProfileLocalDataSource` first.
    2.  **Network Fallback/Refresh**:
        *   If local data exists, return it immediately for a fast UI response.
        *   Simultaneously (or if local is empty), fetch fresh data from `ProfileRemoteDataSource`.
    3.  **Synchronization**: Save the fresh remote data into the local cache for future use.

```dart
// features/profile/data/repositories/profile_repository_impl.dart
@override
Future<Either<Failure, ProfileEntity>> getProfile() async {
  // 1. Try Local Cache
  if (_localDataSource != null && _localDataSource!.hasCachedProfile()) {
     return Right(cachedData.toEntity());
  }
  
  // 2. Fetch Remote
  final response = await _remoteDataSource.getProfile();
  
  // 3. Cache Result
  await _localDataSource?.cacheProfile(response);
  
  return Right(response.toEntity());
}
```

---

## 🔄 Visualizing the Data Flow

The data flows in a unidirectional manner:

```text
[ user_action ]
      ⬇
[ ViewModel ] (States: Loading -> Success/Error)
      ⬇
[ UseCase ] (Pure logic, defines WHAT needs to be done)
      ⬇
[ Repository ] (Interface in Domain,Impl in Data)
      ⬇
[ DataSource ] (Remote API / Local DB)
```

**Key Benefits of this Architecture:**
*   **Maintainability**: Changes in the API or Database don't break the UI or Business Logic.
*   **Testability**: Each layer can be tested independently (e.g., Unit Testing UseCases without UI).
*   **Scalability**: Easy to add new features or swap out implementations.
