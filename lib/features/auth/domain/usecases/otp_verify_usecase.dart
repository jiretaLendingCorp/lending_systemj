import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/auth/domain/repositories/auth_repository.dart';

/// OTP verification use case: verifies a one-time passcode sent to the user's email.
///
/// This completes the signup flow by confirming the user's email
/// address. After successful verification, the user's account
/// is fully activated and they can sign in.
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

/// Parameters for the OTP verification use case.
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
