// lib/features/disbursements/presentation/providers/disbursement_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/disbursements/data/datasources/disbursement_remote_datasource.dart';
import 'package:jireta_loan/features/disbursements/data/repositories/disbursement_repository_impl.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/domain/repositories/disbursement_repository.dart';
import 'package:jireta_loan/features/disbursements/domain/usecases/assign_rider_usecase.dart';
import 'package:jireta_loan/features/disbursements/domain/usecases/mark_delivered_usecase.dart';

sealed class DisbursementFeatureState {
  const DisbursementFeatureState();
}

class DisbursementInitial extends DisbursementFeatureState {
  const DisbursementInitial();
}

class DisbursementsLoading extends DisbursementFeatureState {
  const DisbursementsLoading();
}

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

class DisbursementDetailLoaded extends DisbursementFeatureState {
  final Disbursement disbursement;

  const DisbursementDetailLoaded({required this.disbursement});
}

class DisbursementOperationSuccess extends DisbursementFeatureState {
  final Disbursement disbursement;
  final String message;

  const DisbursementOperationSuccess({
    required this.disbursement,
    required this.message,
  });
}

class DisbursementError extends DisbursementFeatureState {
  final String message;
  final Failure? failure;

  const DisbursementError(this.message, {this.failure});
}

final disbursementRemoteDataSourceProvider =
    Provider<DisbursementRemoteDataSource>((ref) {
  return DisbursementRemoteDataSource(dio: ref.watch(dioProvider));
});

final disbursementRepositoryProvider =
    Provider<DisbursementRepository>((ref) {
  return DisbursementRepositoryImpl(
    remoteDataSource: ref.watch(disbursementRemoteDataSourceProvider),
  );
});

final assignRiderUseCaseProvider = Provider<AssignRiderUseCase>((ref) {
  return AssignRiderUseCase(
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

final markDeliveredUseCaseProvider =
    Provider<MarkDeliveredUseCase>((ref) {
  return MarkDeliveredUseCase(
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

final disbursementFeatureProvider = StateNotifierProvider<
    DisbursementNotifier, DisbursementFeatureState>((ref) {
  return DisbursementNotifier(
    assignRiderUseCase: ref.watch(assignRiderUseCaseProvider),
    markDeliveredUseCase: ref.watch(markDeliveredUseCaseProvider),
    repository: ref.watch(disbursementRepositoryProvider),
  );
});

final disbursementUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AppAuthAuthenticated) {
    return authState.role;
  }
  return null;
});

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

  void resetState() {
    state = const DisbursementInitial();
  }
}
