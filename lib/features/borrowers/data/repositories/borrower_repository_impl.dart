import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/borrowers/data/datasources/borrower_remote_datasource.dart';
import 'package:lendflow/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:lendflow/features/borrowers/domain/repositories/borrower_repository.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/payments/domain/entities/payment.dart';

/// Concrete implementation of [BorrowerRepository].
///
/// Delegates to [BorrowerRemoteDataSource] for all network operations
/// and maps [AppException] subtypes to [Failure] subtypes.
class BorrowerRepositoryImpl implements BorrowerRepository {
  final BorrowerRemoteDataSource _remoteDataSource;

  BorrowerRepositoryImpl({required BorrowerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, BorrowerProfile>> getProfile() async {
    try {
      final profile = await _remoteDataSource.getProfile();
      return Right(profile);
    } on AuthException catch (e) {
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
  Future<Either<Failure, BorrowerProfile>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final profile = await _remoteDataSource.updateProfile(data);
      return Right(profile);
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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
    } on AuthException catch (e) {
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
