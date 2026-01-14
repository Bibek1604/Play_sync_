# Authentication Feature Documentation

## Overview

The Auth feature handles user authentication including registration (Student, Tutor, Admin) and login with token-based authentication. The feature uses Riverpod for state management and integrates with a remote API backend.

## Architecture

The Auth feature follows Clean Architecture with three layers:

### Domain Layer
- **Entity**: `AuthEntity` with user information and role enum
- **Repository**: `IAuthRepository` abstract interface defining auth operations
- **Use Cases**: 
  - `LoginUsecase` - Handle user login
  - `RegisterUsecase` - Handle student registration
  - `RegisterAdminUsecase` - Handle admin registration
  - `RegisterTutorUsecase` - Handle tutor registration

### Data Layer
- **Models**: 
  - `AuthRequestModel` - Request serialization for API
  - `AuthResponseModel` - Response deserialization and entity conversion
- **Data Source**:
  - `IAuthDataSource` - Abstract interface
  - `AuthRemoteDataSource` - Remote API implementation with token management
- **Repository**: `AuthRepositoryImpl` - Repository implementation wrapping data sources

### Presentation Layer
- **State**: `AuthState` with status enum and user data
- **ViewModel**: `AuthViewModel` - Notifier managing authentication state
- **Pages**:
  - `LoginPage` - User login with email and password
  - `RegisterPage` - User registration with role selection

## Provider Chain

```
authViewModelProvider (AuthViewModel, AuthState)
  ├── loginUsecaseProvider (LoginUsecase)
  │   └── authRepositoryProvider (AuthRepositoryImpl)
  │       └── authRemoteDatasourceProvider (AuthRemoteDataSource)
  │           ├── apiClientProvider (ApiClient with Dio)
  │           └── secureStorageProvider (FlutterSecureStorage)
  ├── registerUsecaseProvider (RegisterUsecase)
  │   └── authRepositoryProvider
  ├── registerAdminUsecaseProvider (RegisterAdminUsecase)
  │   └── authRepositoryProvider
  └── registerTutorUsecaseProvider (RegisterTutorUsecase)
      └── authRepositoryProvider
```

## API Endpoints

**Base URL**: `http://localhost:5000` (or `http://10.0.2.2:5000` for Android emulator)

### Endpoints
- `POST /auth/register/user` - Register new student
- `POST /auth/register/admin` - Register new admin
- `POST /auth/register/tutor` - Register new tutor
- `POST /api/auth/login` - Login user

### Request Format
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Response Format
```json
{
  "userId": "uuid-string",
  "email": "user@example.com",
  "role": "student|admin|tutor",
  "token": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "createdAt": "2025-01-01T00:00:00Z"
}
```

## Token Management

### Storage
- **Access Token**: Stored in `FlutterSecureStorage` with key `access_token`
- **Refresh Token**: Stored in `FlutterSecureStorage` with key `refresh_token`
- **User Data**: Stored in `FlutterSecureStorage` with keys:
  - `user_id`
  - `user_email`
  - `user_role`

### Auto-Injection
All non-auth API endpoints automatically inject Bearer token via `_AuthInterceptor`:
```
Authorization: Bearer {access_token}
```

### Error Handling
- **401 Unauthorized**: Token expired, user redirected to login
- **400 Bad Request**: Validation error with specific message
- **403 Forbidden**: Insufficient permissions
- **409 Conflict**: Email already exists (duplicate registration)
- **422 Unprocessable Entity**: Invalid input data
- **500 Internal Server Error**: Server error

## Usage Examples

### Login
```dart
final authViewModel = ref.read(authViewModelProvider.notifier);
await authViewModel.login('user@example.com', 'password123');

// Listen to auth state
ref.listen(authViewModelProvider, (previous, next) {
  if (next.isAuthenticated) {
    // Navigate to dashboard
  } else if (next.hasError) {
    // Show error message
  }
});
```

### Register as Student
```dart
final authViewModel = ref.read(authViewModelProvider.notifier);
await authViewModel.register('student@example.com', 'password123');
```

### Register as Admin
```dart
final authViewModel = ref.read(authViewModelProvider.notifier);
await authViewModel.registerAdmin('admin@example.com', 'password123');
```

### Register as Tutor
```dart
final authViewModel = ref.read(authViewModelProvider.notifier);
await authViewModel.registerTutor('tutor@example.com', 'password123');
```

### Logout
```dart
final authViewModel = ref.read(authViewModelProvider.notifier);
await authViewModel.logout();
```

## Testing with cURL

### Test Student Registration
```bash
curl -X POST http://localhost:5000/auth/register/user \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@example.com",
    "password": "password123"
  }'
```

### Test Admin Registration
```bash
curl -X POST http://localhost:5000/auth/register/admin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123",
    "adminCode": "your-super-secret-key-2025"
  }'
```

### Test Tutor Registration
```bash
curl -X POST http://localhost:5000/auth/register/tutor \
  -H "Content-Type: application/json" \
  -d '{
    "email": "tutor@example.com",
    "password": "tutor123"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Test Protected Endpoint with Token
```bash
curl -X GET http://localhost:5000/api/user/profile \
  -H "Authorization: Bearer {access_token}"
```

## File Structure

```
lib/features/auth/
├── domain/
│   ├── entities/
│   │   └── auth_entity.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login_usecase.dart
│       ├── register_usecase.dart
│       ├── register_admin_usecase.dart
│       └── register_tutor_usecase.dart
├── data/
│   ├── datasources/
│   │   ├── auth_datasource.dart
│   │   └── remote/
│   │       └── auth_remote_datasource.dart
│   ├── models/
│   │   ├── auth_request_model.dart
│   │   └── auth_response_model.dart
│   └── repositories/
│       └── auth_repository_impl.dart
└── presentation/
    ├── pages/
    │   ├── login_page.dart
    │   └── register_page.dart
    ├── state/
    │   └── auth_state.dart
    └── view_model/
        └── auth_viewmodel.dart
```

## Error Handling

The feature uses `dartz` Either type for error handling:
```dart
Either<Failure, AuthEntity>
```

Failures are mapped to appropriate error messages:
- `ApiFailure` - API request/response errors
- `NetworkFailure` - Network connectivity issues
- `AuthFailure` - Authentication specific errors
- `ValidationFailure` - Input validation errors

## Key Features

✅ Multi-role user registration (Student, Tutor, Admin)  
✅ Secure token storage with `FlutterSecureStorage`  
✅ Automatic token injection in requests  
✅ Comprehensive error handling with status code mapping  
✅ Email validation  
✅ Password confirmation in registration  
✅ Loading states and user feedback  
✅ Navigation between login and register pages  
✅ Riverpod-based dependency injection  

## Future Enhancements

- [ ] Password reset functionality
- [ ] Email verification
- [ ] Social login (Google, Apple)
- [ ] Biometric authentication
- [ ] Refresh token rotation
- [ ] Two-factor authentication
- [ ] Remember me functionality

## Dependencies

- `flutter_riverpod: ^2.4.0` - State management
- `dio: ^5.3.3` - HTTP client
- `flutter_secure_storage: ^9.0.0` - Secure token storage
- `dartz: ^0.10.1` - Either type for error handling
- `equatable: ^2.0.5` - Value equality

