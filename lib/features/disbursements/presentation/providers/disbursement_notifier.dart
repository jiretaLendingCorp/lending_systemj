import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/disbursements/data/datasources/disbursement_remote_datasource.dart';
import 'package:lendflow/features/disbursements/data/repositories/disbursement_repository_impl.dart';
import 'package:lendflow/features/disbursements/domain/entities/disbursement.dart';
import 'package:lendflow/features/disbursements/domain/repositories/disbursement_repository.dart';
import 'package:lendflow/features/disbursements/domain/usecases/assign_rider_usecase.dart';
import 'package:lendflow/features/disbursements/domain/usecases/mark_delivered_usecase.dart';

// ─────────────────────────────────────────────────────────────────
// Disbursement state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level disbursement state.
sealed class DisbursementFeatureState {
  const DisbursementFeatureState();
}

/// Initial state.
class DisbursementInitial extends DisbursementFeatureState {
  const DisbursementInitial();
}

/// Disbursements are being loaded.
class DisbursementsLoading extends DisbursementFeatureState {
  const DisbursementsLoading();
}

/// Disbursements loaded successfully.
class DisbursementsLoaded extends DisbursementFeatureState {
  final List<Disbursement> disbursements;
  final int total;
  final String? activeStatusFilter;
  final String? activeMethodFilter;
  final int currentPage;

  const DisbursementsLoaded({
    required this.disbursements,
    required this.total,
    this.activeStatusFilter,
    this.activeMethodFilter,
    this.currentPage = 1,
  });

  bool get hasMore => disbursements.length < total;
}

/// Single disbursement detail loaded.
class DisbursementDetailLoaded extends DisbursementFeatureState {
  final Disbursement disbursement;

  const DisbursementDetailLoaded({required this.disbursement});
}

/// Disbursement operation succeeded.
class DisbursementOperationSuccess extends DisbursementFeatureState {
  final Disbursement disbursement;
  final String message;

  const DisbursementOperationSuccess({
    required this.disbursement,
    required this.message,
  });
}

/// An error occurred.
class DisbursementError extends DisbursementFeatureState {
  final String message;
  final Failure? failure;

  const DisbursementError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [DisbursementRemoteDataSource].
final disbursementRemoteDataSourceProvider =
    Provider<DisbursementRemoteDataSource>((ref) {
  return DisbursementRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [DisbursementRepository] implementation.
final disbursementRepositoryProvider =
    Provider<DisbursementRepository>((ref) {
  return DisbursementRepositoryImpl(
    remoteDataSource: ref.watch(disbursementRemoteDataSourceProvider),
  );
});

/// Provides the [AssignRiderUseCase].
final assignRiderUseCaseProvider = Provider<AssignRiderUseCase>((ref) {
  return AssignRiderUseCase(
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

/// Provides the [MarkDeliveredUseCase].
final markDeliveredUseCaseProvider =
    Provider<MarkDeliveredUseCase>((ref) {
  return MarkDeliveredUseCase(
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

/// Provides the [DisbursementNotifier].
final disbursementFeatureProvider = StateNotifierProvider<
    DisbursementNotifier, DisbursementFeatureState>((ref) {
  return DisbursementNotifier(
    assignRiderUseCase: ref.watch(assignRiderUseCaseProvider),
    markDeliveredUseCase: ref.watch(markDeliveredUseCaseProvider),
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

/// Provider for the current user's role.
final disbursementUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.role;
  }
  return null;
});

// ─────────────────────────────────────────────────────────────────
// Disbursement notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing disbursement feature UI state.
class DisbursementNotifier
    extends StateNotifier<DisbursementFeatureState> {
  final AssignRiderUseCase _assignRiderUseCase;
  final MarkDeliveredUseCase _markDeliveredUseCase;
  final DisbursementRepository _repository;

  DisbursementNotifier({
    required AssignRiderUseCase assignRiderUseCase,
    required MarkDeliveredUseCase markDeliveredUseCase,
    required DisbursementRepository repository,
  })  : _assignRiderUseCase = assignRiderUseCase,
        _markDeliveredUseCase = markDeliveredUseCase,
        _repository = repository,
        super(const DisbursementInitial());

  /// Load disbursements with optional filters.
  Future<void> loadDisbursements({
    String? status,
    String? method,
    String? riderId,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const DisbursementsLoading();
    }

    final result = await _repository.list(
      status: status,
      method: method,
      riderId: riderId,
      page: page,
    );

    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (listResult) {
        final existing = state is DisbursementsLoaded && page > 1
            ? (state as DisbursementsLoaded).disbursements
            : <Disbursement>[];
        return DisbursementsLoaded(
          disbursements: [...existing, ...listResult.disbursements],
          total: listResult.total,
          activeStatusFilter: status,
          activeMethodFilter: method,
          currentPage: page,
        );
      },
    );
  }

  /// Load more disbursements (pagination).
  Future<void> loadMore({String? riderId}) async {
    if (state is! DisbursementsLoaded) return;
    final current = state as DisbursementsLoaded;
    if (!current.hasMore) return;

    await loadDisbursements(
      status: current.activeStatusFilter,
      method: current.activeMethodFilter,
      riderId: riderId,
      page: current.currentPage + 1,
    );
  }

  /// Load a single disbursement's detail.
  Future<void> loadDisbursementDetail(String disbursementId) async {
    state = const DisbursementsLoading();

    final result = await _repository.detail(disbursementId);
    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (disbursement) =>
          DisbursementDetailLoaded(disbursement: disbursement),
    );
  }

  /// Assign a rider to a disbursement.
  Future<void> assignRider({
    required String disbursementId,
    required String riderId,
  }) async {
    final result = await _assignRiderUseCase(
      AssignRiderParams(
        disbursementId: disbursementId,
        riderId: riderId,
      ),
    );

    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (disbursement) => DisbursementOperationSuccess(
        disbursement: disbursement,
        message: 'Rider assigned successfully.',
      ),
    );
  }

  /// Mark a disbursement as in transit.
  Future<void> markInTransit(String disbursementId) async {
    final result = await _repository.markInTransit(disbursementId);
    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (disbursement) => DisbursementOperationSuccess(
        disbursement: disbursement,
        message: 'Disbursement marked as in transit.',
      ),
    );
  }

  /// Mark a disbursement as delivered (rider action).
  Future<void> markDelivered({
    required String disbursementId,
    required double latitude,
    required double longitude,
    String? receiptPhotoUrl,
  }) async {
    final result = await _markDeliveredUseCase(
      MarkDeliveredParams(
        disbursementId: disbursementId,
        latitude: latitude,
        longitude: longitude,
        receiptPhotoUrl: receiptPhotoUrl,
      ),
    );

    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (disbursement) => DisbursementOperationSuccess(
        disbursement: disbursement,
        message: 'Disbursement marked as delivered.',
      ),
    );
  }

  /// Mark a disbursement as failed.
  Future<void> markFailed(String disbursementId, {String? reason}) async {
    final result =
        await _repository.markFailed(disbursementId, reason: reason);
    state = result.fold(
      (failure) =>
          DisbursementError(failure.message, failure: failure),
      (disbursement) => DisbursementOperationSuccess(
        disbursement: disbursement,
        message: 'Disbursement marked as failed.',
      ),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const DisbursementInitial();
  }
}
