import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/auth/domain/repositories/auth_repository.dart';

/// Signup use case: registers a new user account.
///
/// Enforces the business rule that self-registration is limited
/// to borrower and rider roles. Admin and manager accounts must
/// be created through the admin panel.
class SignupUseCase {
  final AuthRepository _repository;

  SignupUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, User>> call(SignupParams params) {
    // Validate that only self-registrable roles are used
    final role = params.role.toLowerCase();
    if (role != 'borrower' && role != 'rider') {
      return Future.value(const Left(ValidationFailure(
        message: 'Self-registration is only available for borrower and rider roles.',
        fieldErrors: {'role': 'Only borrower and rider roles can self-register.'},
      )));
    }

    return _repository.signup(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      phone: params.phone,
      role: role,
    );
  }
}

/// Parameters for the signup use case.
class SignupParams extends Equatable {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String role;

  const SignupParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone, role];
}
