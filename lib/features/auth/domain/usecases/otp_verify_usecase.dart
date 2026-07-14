// lib/features/auth/domain/usecases/otp_verify_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';
import 'package:jireta_loan/features/auth/domain/repositories/auth_repository.dart';

class OtpVerifyUseCase {
  final AuthRepository _repository;

  OtpVerifyUseCase({required AuthRepository repository})
      : _repository = repository;

  Future<Either<Failure, User>> call(OtpVerifyParams params) {
    return _repository.otpVerify(
      email: params.email,
      otp: params.otp,
    );
  }
}

class OtpVerifyParams extends Equatable {
  final String email;
  final String otp;

  const OtpVerifyParams({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}
