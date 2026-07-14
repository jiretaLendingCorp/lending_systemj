// lib/features/auth/domain/usecases/logout_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
