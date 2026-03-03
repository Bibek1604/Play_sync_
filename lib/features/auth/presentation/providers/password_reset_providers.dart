import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/password_reset_remote_datasource.dart';
import '../../data/repositories/password_reset_repository_impl.dart';
import '../../domain/repositories/password_reset_repository.dart';
import '../../domain/usecases/password_reset_usecases.dart';
import 'password_reset_notifier.dart';
import '../../../../core/api/api_client.dart';

// ─── Data Source Provider ────────────────────────────────────────────────────

final passwordResetDataSourceProvider = Provider<PasswordResetRemoteDataSource>(
  (ref) {
    final dio = ref.watch(apiClientProvider).dio;
    return PasswordResetRemoteDataSourceImpl(dio: dio);
  },
);

// ─── Repository Provider ─────────────────────────────────────────────────────

final passwordResetRepositoryProvider = Provider<PasswordResetRepository>(
  (ref) {
    final dataSource = ref.watch(passwordResetDataSourceProvider);
    return PasswordResetRepositoryImpl(remoteDataSource: dataSource);
  },
);

// ─── UseCase Providers ───────────────────────────────────────────────────────

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>(
  (ref) {
    final repository = ref.watch(passwordResetRepositoryProvider);
    return ForgotPasswordUseCase(repository);
  },
);

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) {
    final repository = ref.watch(passwordResetRepositoryProvider);
    return ResetPasswordUseCase(repository);
  },
);

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>(
  (ref) {
    final repository = ref.watch(passwordResetRepositoryProvider);
    return VerifyOtpUseCase(repository);
  },
);

// ─── State Notifier Provider ─────────────────────────────────────────────────

final passwordResetNotifierProvider =
    StateNotifierProvider<PasswordResetNotifier, PasswordResetState>(
  (ref) {
    return PasswordResetNotifier(
      forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
      resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
      verifyOtpUseCase: ref.watch(verifyOtpUseCaseProvider),
    );
  },
);
