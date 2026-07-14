// lib/features/auth/domain/usecases/signup_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';
import 'package:jireta_loan/features/auth/domain/repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository _repository;

  SignupUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, User>> call(SignupParams params) {
    final role = params.role.toLowerCase();
    if (role != 'lender' && role != 'rider') {
      return Future.value(const Left(ValidationFailure(
        message: 'Self-registration is only available for lender and rider roles.',
        fieldErrors: {'role': 'Only lender and rider roles can self-register.'},
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
