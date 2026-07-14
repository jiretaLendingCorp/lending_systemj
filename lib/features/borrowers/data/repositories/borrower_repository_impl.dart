// lib/features/lenders/data/repositories/borrower_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/lenders/data/datasources/borrower_remote_datasource.dart';
import 'package:jireta_loan/features/lenders/domain/entities/lender_profile.dart';
import 'package:jireta_loan/features/lenders/domain/repositories/borrower_repository.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

class BorrowerRepositoryImpl implements LenderRepository {
  final BorrowerRemoteDataSource _remoteDataSource;

  BorrowerRepositoryImpl({required BorrowerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, LenderProfile>> getProfile() async {
    try {
      final profile = await _remoteDataSource.getProfile();
      return Right(profile);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LenderProfile>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final profile = await _remoteDataSource.updateProfile(data);
      return Right(profile);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Loan>>> getOwnLoans({
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final loans = await _remoteDataSource.getOwnLoans(
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Right(loans);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getOwnPayments({
    String? loanId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final payments = await _remoteDataSource.getOwnPayments(
        loanId: loanId,
        page: page,
        pageSize: pageSize,
      );
      return Right(payments);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
