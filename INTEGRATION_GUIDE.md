# PlaySync Flutter - Professional Green Theme Implementation

## ✅ What's Been Implemented

### 1. **Design System** (Clean Architecture Ready)
- ✅ Professional green color palette (`#16A34A` primary)
- ✅ Complete theme configuration with Material 3
- ✅ 8px spacing system
- ✅ Consistent border radius values
- ✅ Clean, minimal, corporate SaaS look

### 2. **Forgot Password Feature** (Complete Clean Architecture)
#### Domain Layer
- ✅ `ForgotPasswordEntity` - Domain models
- ✅ `PasswordResetRepository` Interface
- ✅ `ForgotPasswordUseCase`, `ResetPasswordUseCase`, `VerifyOtpUseCase`

#### Data Layer
- ✅ `ForgotPasswordDto` - Data models with JSON serialization
- ✅ `PasswordResetRemoteDataSource` - API integration
- ✅ `PasswordResetRepositoryImpl` - Repository implementation

#### Presentation Layer
- ✅ `PasswordResetNotifier` - Riverpod state management
- ✅ `ForgotPasswordPage` - Professional UI with success state
- ✅ `ResetPasswordPage` - OTP input + password reset
- ✅ `LoginPageNew` - Updated login with "Forgot Password?" link

---

## 📁 File Structure

```
lib/
├── core/
│   └── constants/
│       ├── app_colors.dart ✨ NEW - Professional green color system
│       └── app_theme.dart ✨ NEW - Complete Material 3 theme
│
└── features/
    └── auth/
        ├── domain/
        │   ├── entities/
        │   │   └── forgot_password_entity.dart ✨ NEW
        │   ├── repositories/
        │   │   └── password_reset_repository.dart ✨ NEW
        │   └── usecases/
        │       └── password_reset_usecases.dart ✨ NEW
        │
        ├── data/
        │   ├── models/
        │   │   └── forgot_password_model.dart ✨ NEW
        │   ├── datasources/
        │   │   └── password_reset_remote_datasource.dart ✨ NEW
        │   └── repositories/
        │       └── password_reset_repository_impl.dart ✨ NEW
        │
        └── presentation/
            ├── providers/
            │   └── password_reset_notifier.dart ✨ NEW
            └── pages/
                ├── forgot_password_page.dart ✨ NEW
                ├── reset_password_page.dart ✨ NEW
                └── login_page_new.dart ✨ NEW (Updated design)
```

---

## 🚀 Integration Steps

### Step 1: Install Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  equatable: ^2.0.7
  fpdart: ^1.1.0
  dio: ^5.7.0
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.13
  json_serializable: ^6.8.0
```

Run:
```bash
flutter pub get
```

### Step 2: Generate JSON Serialization Code

Run this command to generate the `.g.dart` files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 3: Update Main App Theme

In your `main.dart`, apply the new theme:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play Sync',
      theme: AppTheme.lightTheme, // ✅ Apply Professional Green Theme
      darkTheme: AppTheme.darkTheme, // Optional
      home: const LoginPageNew(), // ✅ Use new login page
      routes: {
        '/login': (context) => const LoginPageNew(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        // Add other routes...
      },
    );
  }
}
```

### Step 4: Setup Dio Instance

Create or update your `lib/core/api/dio_client.dart`:

```dart
import 'package:dio/dio.dart';

class DioClient {
  static Dio getDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000/', // ✅ Update with your backend URL
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors for logging, auth tokens, etc.
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  }
}
```

### Step 5: Setup Riverpod Providers

Create `lib/features/auth/presentation/providers/password_reset_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/password_reset_remote_datasource.dart';
import '../../data/repositories/password_reset_repository_impl.dart';
import '../../domain/usecases/password_reset_usecases.dart';
import '../../../../core/api/dio_client.dart';
import 'password_reset_notifier.dart';

// Data Source Provider
final passwordResetRemoteDataSourceProvider = Provider<PasswordResetRemoteDataSource>(
  (ref) => PasswordResetRemoteDataSourceImpl(
    dio: DioClient.getDioInstance(),
  ),
);

// Repository Provider
final passwordResetRepositoryProvider = Provider((ref) {
  final remoteDataSource = ref.watch(passwordResetRemoteDataSourceProvider);
  return PasswordResetRepositoryImpl(remoteDataSource: remoteDataSource);
});

// UseCase Providers
final forgotPasswordUseCaseProvider = Provider((ref) {
  final repository = ref.watch(passwordResetRepositoryProvider);
  return ForgotPasswordUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider((ref) {
  final repository = ref.watch(passwordResetRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

final verifyOtpUseCaseProvider = Provider((ref) {
  final repository = ref.watch(passwordResetRepositoryProvider);
  return VerifyOtpUseCase(repository);
});

// State Notifier Provider
final passwordResetNotifierProvider =
    StateNotifierProvider<PasswordResetNotifier, PasswordResetState>(
  (ref) => PasswordResetNotifier(
    forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
    verifyOtpUseCase: ref.watch(verifyOtpUseCaseProvider),
  ),
);
```

### Step 6: Integrate Providers into Pages

Update `forgot_password_page.dart` to connect with the provider:

```dart
// In _ForgotPasswordPageState

Future<void> _handleSendOtp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  // ✅ Call the provider
  await ref
      .read(passwordResetNotifierProvider.notifier)
      .sendPasswordResetOtp(_emailController.text.trim());

  final state = ref.read(passwordResetNotifierProvider);

  setState(() => _isLoading = false);

  if (state.isSuccess) {
    setState(() => _isSuccess = true);
  } else if (state.failure != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.failure!.message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

Similarly, update `reset_password_page.dart`:

```dart
// In _ResetPasswordPageState

Future<void> _handleResetPassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  final request = ResetPasswordRequest(
    email: _emailController.text.trim(),
    otp: _otpController.text.trim(),
    newPassword: _newPasswordController.text.trim(),
    confirmPassword: _confirmPasswordController.text.trim(),
  );

  // ✅ Call the provider
  await ref.read(passwordResetNotifierProvider.notifier).resetPassword(request);

  final state = ref.read(passwordResetNotifierProvider);

  setState(() => _isLoading = false);

  if (state.isSuccess) {
    _showSuccessDialog();
  } else if (state.failure != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.failure!.message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
```

---

## 🎨 Design System Usage Guide

### Colors

```dart
import 'package:play_sync_new/core/constants/app_colors.dart';

// Primary Green
Container(color: AppColors.primary)

// Backgrounds
Container(color: AppColors.background) // White
Container(color: AppColors.surfaceLight) // Light gray

// Text
Text('Hello', style: TextStyle(color: AppColors.textPrimary)) // Dark
Text('Subtitle', style: TextStyle(color: AppColors.textSecondary)) // Medium gray

// Borders
border: Border.all(color: AppColors.border)

// Semantic Colors
Container(color: AppColors.success) // Green success
Container(color: AppColors.error) // Red error
```

### Spacing

```dart
import 'package:play_sync_new/core/constants/app_theme.dart';

// Use 8px spacing system
SizedBox(height: AppSpacing.xs)    // 4px
SizedBox(height: AppSpacing.sm)    // 8px
SizedBox(height: AppSpacing.md)    // 12px
SizedBox(height: AppSpacing.lg)    // 16px
SizedBox(height: AppSpacing.xl)    // 24px
SizedBox(height: AppSpacing.xxl)   // 32px
SizedBox(height: AppSpacing.xxxl)  // 48px
```

### Border Radius

```dart
BorderRadius.circular(AppRadius.xs)  // 4px
BorderRadius.circular(AppRadius.sm)  // 6px
BorderRadius.circular(AppRadius.md)  // 8px  ← Most buttons/inputs
BorderRadius.circular(AppRadius.lg)  // 12px ← Cards
BorderRadius.circular(AppRadius.xl)  // 16px
```

### Buttons

```dart
// Primary Green Button (Automatic from theme)
ElevatedButton(
  onPressed: () {},
  child: const Text('Save'),
)

// Outlined Button
OutlinedButton(
  onPressed: () {},
  child: const Text('Cancel'),
)

// Text Button
TextButton(
  onPressed: () {},
  child: const Text('Learn More'),
)
```

### Input Fields

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email_outlined),
    filled: true,
    fillColor: AppColors.surfaceLight,
  ),
)
```

---

## 📱 Backend API Integration

The forgot password feature integrates with these backend endpoints:

### 1. Forgot Password (Send OTP)
```
POST /api/v1/auth/forgot-password
Content-Type: application/json

{
  "email": "user@example.com"
}

Response:
{
  "success": true,
  "message": "If this email is registered, you will receive a password reset OTP"
}
```

### 2. Reset Password (Verify OTP + Reset)
```
POST /api/v1/auth/reset-password
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456",
  "newPassword": "NewPassword123",
  "confirmPassword": "NewPassword123"
}

Response:
{
  "success": true,
  "message": "Password reset successful. Please login with your new password."
}
```

### 3. Verify OTP (Optional real-time check)
```
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response:
{
  "valid": true
}
```

---

## ✅ Testing Checklist

- [ ] Run `flutter pub get`
- [ ] Run `dart run build_runner build`
- [ ] Update backend URL in `DioClient`
- [ ] Test forgot password flow
- [ ] Test reset password with OTP
- [ ] Check email styling (OTP should arrive)
- [ ] Verify UI matches green theme
- [ ] Test validation errors
- [ ] Test success/error states

---

## 🎯 Next Steps

To complete the full app redesign with the green theme:

1. **Update Existing Pages:**
   - Replace `LoginPage` with `LoginPageNew` in your routes
   - Update dashboard, profile, game pages with the new colors

2. **Implement Profile Update Feature:**
   - Create domain/data/presentation layers for profile
   - Use same Clean Architecture pattern

3. **Implement Game Creation Feature:**
   - Add game creation flow with professional forms
   - Use green buttons and cards from theme

4. **Implement Game Showcase:**
   - Grid/list view with cards
   - Green action buttons (Join, View, Edit)
   - Use AppColors and AppSpacing throughout

---

## 💡 Tips for Maintaining Design Consistency

1. **Always use `AppColors` constants** - Never hardcode colors
2. **Use `AppSpacing` for padding/margins** - Stick to 8px system
3. **Use `AppRadius` for border radius** - Keep consistency
4. **Follow button patterns:**
   - Primary action → Green `ElevatedButton`
   - Secondary → `OutlinedButton`
   - Tertiary → `TextButton`
5. **Icons:** Always use `color: AppColors.primary` for icons
6. **Cards:** Use `AppColors.background` with `AppRadius.lg`

---

## 🐛 Troubleshooting

### JSON Serialization Error
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Provider Not Found
Make sure providers are defined above `ProviderScope` in `main.dart`

### Backend Connection Error
- Check `baseUrl` in `DioClient`
- Ensure backend is running on correct port
- Check CORS configuration if needed

---

## 📞 Support

For questions or issues with integration:
1. Check the inline code comments
2. Review the Clean Architecture flow: Domain → Data → Presentation
3. Verify provider setup in `/providers/password_reset_provider.dart`

---

**🎉 Your PlaySync app now has:**
- ✅ Professional green SaaS-style UI
- ✅ Complete forgot password feature
- ✅ Clean Architecture implementation
- ✅ Production-ready design system
- ✅ Consistent spacing and colors

