import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/auth/domain/repositories/auth_repository.dart';

/// Login use case: authenticates a user with email and password.
///
/// Encapsulates the business rule that login requires both an email
/// and a password, and returns either a [User] or a [Failure].
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, User>> call(LoginParams params) {
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

/// Parameters for the login use case.
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
