import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

/// Permanently deletes the authenticated user's account and wipes local data.
/// This action is irreversible.
class DeleteAccountUsecase implements UsecaseWithoutParams<void> {
  final IProfileRepository _repository;

  const DeleteAccountUsecase({required IProfileRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call() {
    return _repository.deleteAccount();
  }
}
