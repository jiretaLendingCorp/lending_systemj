// lib/features/borrowers/presentation/providers/borrower_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/borrowers/data/datasources/borrower_remote_datasource.dart';
import 'package:jireta_loan/features/borrowers/data/repositories/borrower_repository_impl.dart';
import 'package:jireta_loan/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:jireta_loan/features/borrowers/domain/repositories/borrower_repository.dart';
import 'package:jireta_loan/features/borrowers/domain/usecases/get_borrower_profile_usecase.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

sealed class BorrowerFeatureState {
  const BorrowerFeatureState();
}

class BorrowerInitial extends BorrowerFeatureState {
  const BorrowerInitial();
}

class BorrowerLoading extends BorrowerFeatureState {
  const BorrowerLoading();
}

class BorrowerProfileLoaded extends BorrowerFeatureState {
  final LenderProfile profile;
  final List<Loan> activeLoans;
  final List<Payment> recentPayments;

  const BorrowerProfileLoaded({
    required this.profile,
    this.activeLoans = const [],
    this.recentPayments = const [],
  });

  Loan? get currentLoan => activeLoans.isNotEmpty ? activeLoans.first : null;

  bool get hasActiveLoan => activeLoans.isNotEmpty;
}

class BorrowerProfileUpdated extends BorrowerFeatureState {
  final LenderProfile profile;

  const BorrowerProfileUpdated({required this.profile});
}

class BorrowerLoansLoaded extends BorrowerFeatureState {
  final List<Loan> loans;

  const BorrowerLoansLoaded({required this.loans});
}

class BorrowerPaymentsLoaded extends BorrowerFeatureState {
  final List<Payment> payments;

  const BorrowerPaymentsLoaded({required this.payments});
}

class BorrowerError extends BorrowerFeatureState {
  final String message;
  final Failure? failure;

  const BorrowerError(this.message, {this.failure});
}

final borrowerRemoteDataSourceProvider =
    Provider<BorrowerRemoteDataSource>((ref) {
  return BorrowerRemoteDataSource(dio: ref.watch(dioProvider));
});

final borrowerRepositoryProvider = Provider<LenderRepository>((ref) {
  return BorrowerRepositoryImpl(
    remoteDataSource: ref.watch(borrowerRemoteDataSourceProvider),
  );
});

final getBorrowerProfileUseCaseProvider =
    Provider<GetBorrowerProfileUseCase>((ref) {
  return GetBorrowerProfileUseCase(
      repository: ref.watch(borrowerRepositoryProvider));
});

final borrowerFeatureProvider =
    StateNotifierProvider<LenderNotifier, BorrowerFeatureState>((ref) {
  return LenderNotifier(
    getBorrowerProfileUseCase: ref.watch(getBorrowerProfileUseCaseProvider),
    repository: ref.watch(borrowerRepositoryProvider),
  );
});

class LenderNotifier extends StateNotifier<BorrowerFeatureState> {
  final GetBorrowerProfileUseCase _getBorrowerProfileUseCase;
  final LenderRepository _repository;

  LenderNotifier({
    required GetBorrowerProfileUseCase getBorrowerProfileUseCase,
    required LenderRepository repository,
  })  : _getBorrowerProfileUseCase = getBorrowerProfileUseCase,
        _repository = repository,
        super(const BorrowerInitial());

  Future<void> loadProfile() async {
    state = const BorrowerLoading();

    final profileResult = await _getBorrowerProfileUseCase();

    await profileResult.fold(
      (failure) async {
        state = BorrowerError(failure.message, failure: failure);
      },
      (profile) async {
        final loansResult = await _repository.getOwnLoans(status: 'active');
        final paymentsResult = await _repository.getOwnPayments();

        final activeLoans = loansResult.fold(
          (failure) => <Loan>[],
          (loans) => loans,
        );

        final recentPayments = paymentsResult.fold(
          (failure) => <Payment>[],
          (payments) => payments,
        );

        state = BorrowerProfileLoaded(
          profile: profile,
          activeLoans: activeLoans,
          recentPayments: recentPayments,
        );
      },
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final result = await _repository.updateProfile(data);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (profile) => BorrowerProfileUpdated(profile: profile),
    );
  }

  Future<void> loadLoans({String? status}) async {
    final result = await _repository.getOwnLoans(status: status);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (loans) => BorrowerLoansLoaded(loans: loans),
    );
  }

  Future<void> loadPayments({String? loanId}) async {
    final result = await _repository.getOwnPayments(loanId: loanId);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (payments) => BorrowerPaymentsLoaded(payments: payments),
    );
  }

  void resetState() {
    state = const BorrowerInitial();
  }
}
