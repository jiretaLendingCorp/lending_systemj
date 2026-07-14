import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/auth/domain/repositories/auth_repository.dart';

/// Logout use case: signs out the current user and clears session data.
///
/// Always succeeds from the domain perspective. Even if the server-side
/// logout call fails, the local session is cleared by the auth state
/// management layer. This ensures the user is always fully logged out
/// regardless of network conditions.
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
