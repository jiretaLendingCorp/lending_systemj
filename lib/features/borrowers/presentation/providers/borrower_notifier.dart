import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/borrowers/data/datasources/borrower_remote_datasource.dart';
import 'package:lendflow/features/borrowers/data/repositories/borrower_repository_impl.dart';
import 'package:lendflow/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:lendflow/features/borrowers/domain/repositories/borrower_repository.dart';
import 'package:lendflow/features/borrowers/domain/usecases/get_borrower_profile_usecase.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/payments/domain/entities/payment.dart';

// ─────────────────────────────────────────────────────────────────
// Borrower state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level borrower state managed by [BorrowerNotifier].
sealed class BorrowerFeatureState {
  const BorrowerFeatureState();
}

/// Initial state.
class BorrowerInitial extends BorrowerFeatureState {
  const BorrowerInitial();
}

/// Loading state.
class BorrowerLoading extends BorrowerFeatureState {
  const BorrowerLoading();
}

/// Profile loaded successfully.
class BorrowerProfileLoaded extends BorrowerFeatureState {
  final BorrowerProfile profile;
  final List<Loan> activeLoans;
  final List<Payment> recentPayments;

  const BorrowerProfileLoaded({
    required this.profile,
    this.activeLoans = const [],
    this.recentPayments = const [],
  });

  /// The borrower's current active loan (if any).
  Loan? get currentLoan => activeLoans.isNotEmpty ? activeLoans.first : null;

  /// Whether the borrower has an active loan.
  bool get hasActiveLoan => activeLoans.isNotEmpty;
}

/// Profile update succeeded.
class BorrowerProfileUpdated extends BorrowerFeatureState {
  final BorrowerProfile profile;

  const BorrowerProfileUpdated({required this.profile});
}

/// Loans loaded.
class BorrowerLoansLoaded extends BorrowerFeatureState {
  final List<Loan> loans;

  const BorrowerLoansLoaded({required this.loans});
}

/// Payments loaded.
class BorrowerPaymentsLoaded extends BorrowerFeatureState {
  final List<Payment> payments;

  const BorrowerPaymentsLoaded({required this.payments});
}

/// An error occurred.
class BorrowerError extends BorrowerFeatureState {
  final String message;
  final Failure? failure;

  const BorrowerError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [BorrowerRemoteDataSource].
final borrowerRemoteDataSourceProvider =
    Provider<BorrowerRemoteDataSource>((ref) {
  return BorrowerRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [BorrowerRepository] implementation.
final borrowerRepositoryProvider = Provider<BorrowerRepository>((ref) {
  return BorrowerRepositoryImpl(
    remoteDataSource: ref.watch(borrowerRemoteDataSourceProvider),
  );
});

/// Provides the [GetBorrowerProfileUseCase].
final getBorrowerProfileUseCaseProvider =
    Provider<GetBorrowerProfileUseCase>((ref) {
  return GetBorrowerProfileUseCase(
      repository: ref.watch(borrowerRepositoryProvider));
});

/// Provides the [BorrowerNotifier] for borrower feature screens.
final borrowerFeatureProvider =
    StateNotifierProvider<BorrowerNotifier, BorrowerFeatureState>((ref) {
  return BorrowerNotifier(
    getBorrowerProfileUseCase: ref.watch(getBorrowerProfileUseCaseProvider),
    repository: ref.watch(borrowerRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Borrower notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing borrower feature UI state.
class BorrowerNotifier extends StateNotifier<BorrowerFeatureState> {
  final GetBorrowerProfileUseCase _getBorrowerProfileUseCase;
  final BorrowerRepository _repository;

  BorrowerNotifier({
    required GetBorrowerProfileUseCase getBorrowerProfileUseCase,
    required BorrowerRepository repository,
  })  : _getBorrowerProfileUseCase = getBorrowerProfileUseCase,
        _repository = repository,
        super(const BorrowerInitial());

  /// Load the borrower's profile with their active loans and recent payments.
  Future<void> loadProfile() async {
    state = const BorrowerLoading();

    final profileResult = await _getBorrowerProfileUseCase();

    await profileResult.fold(
      (failure) async {
        state = BorrowerError(failure.message, failure: failure);
      },
      (profile) async {
        // Load active loans alongside the profile
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

  /// Update the borrower's profile information.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final result = await _repository.updateProfile(data);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (profile) => BorrowerProfileUpdated(profile: profile),
    );
  }

  /// Load the borrower's own loans.
  Future<void> loadLoans({String? status}) async {
    final result = await _repository.getOwnLoans(status: status);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (loans) => BorrowerLoansLoaded(loans: loans),
    );
  }

  /// Load the borrower's payment history.
  Future<void> loadPayments({String? loanId}) async {
    final result = await _repository.getOwnPayments(loanId: loanId);

    state = result.fold(
      (failure) => BorrowerError(failure.message, failure: failure),
      (payments) => BorrowerPaymentsLoaded(payments: payments),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const BorrowerInitial();
  }
}
