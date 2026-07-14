import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/riders/data/datasources/rider_remote_datasource.dart';
import 'package:lendflow/features/riders/data/repositories/rider_repository_impl.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';
import 'package:lendflow/features/riders/domain/repositories/rider_repository.dart';
import 'package:lendflow/features/riders/domain/usecases/complete_task_usecase.dart';
import 'package:lendflow/features/riders/domain/usecases/get_today_tasks_usecase.dart';
import 'package:lendflow/features/riders/domain/usecases/gps_checkin_usecase.dart';

// ─────────────────────────────────────────────────────────────────
// Rider state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level rider state managed by [RiderNotifier].
sealed class RiderFeatureState {
  const RiderFeatureState();
}

/// Initial state.
class RiderInitial extends RiderFeatureState {
  const RiderInitial();
}

/// Tasks are being loaded.
class RiderLoading extends RiderFeatureState {
  const RiderLoading();
}

/// Today's tasks loaded successfully.
class RiderTasksLoaded extends RiderFeatureState {
  final List<RiderTask> tasks;
  final String? activeFilter;

  const RiderTasksLoaded({
    required this.tasks,
    this.activeFilter,
  });

  /// Tasks filtered as disbursements.
  List<RiderTask> get disbursementTasks =>
      tasks.where((t) => t.isDisbursement).toList();

  /// Tasks filtered as collections.
  List<RiderTask> get collectionTasks =>
      tasks.where((t) => t.isCollection).toList();

  /// Pending tasks count.
  int get pendingCount =>
      tasks.where((t) => t.status == RiderTaskStatus.pending || t.status == RiderTaskStatus.assigned).length;

  /// Completed tasks count.
  int get completedCount =>
      tasks.where((t) => t.status == RiderTaskStatus.completed).length;

  /// In-transit tasks count.
  int get inTransitCount =>
      tasks.where((t) => t.status == RiderTaskStatus.inTransit).length;
}

/// History tasks loaded.
class RiderHistoryLoaded extends RiderFeatureState {
  final List<RiderTask> tasks;
  final int page;
  final bool hasMore;

  const RiderHistoryLoaded({
    required this.tasks,
    this.page = 1,
    this.hasMore = false,
  });
}

/// GPS check-in result.
class GpsCheckinResult extends RiderFeatureState {
  final RiderTask task;
  final bool success;

  const GpsCheckinResult({
    required this.task,
    required this.success,
  });
}

/// Task completion result.
class TaskCompleted extends RiderFeatureState {
  final RiderTask task;
  final String message;

  const TaskCompleted({
    required this.task,
    required this.message,
  });
}

/// An error occurred.
class RiderError extends RiderFeatureState {
  final String message;
  final Failure? failure;

  const RiderError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [RiderRemoteDataSource].
final riderRemoteDataSourceProvider = Provider<RiderRemoteDataSource>((ref) {
  return RiderRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [RiderRepository] implementation.
final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepositoryImpl(
    remoteDataSource: ref.watch(riderRemoteDataSourceProvider),
  );
});

/// Provides the [GetTodayTasksUseCase].
final getTodayTasksUseCaseProvider = Provider<GetTodayTasksUseCase>((ref) {
  return GetTodayTasksUseCase(repository: ref.watch(riderRepositoryProvider));
});

/// Provides the [GpsCheckinUseCase].
final gpsCheckinUseCaseProvider = Provider<GpsCheckinUseCase>((ref) {
  return GpsCheckinUseCase(repository: ref.watch(riderRepositoryProvider));
});

/// Provides the [CompleteTaskUseCase].
final completeTaskUseCaseProvider = Provider<CompleteTaskUseCase>((ref) {
  return CompleteTaskUseCase(repository: ref.watch(riderRepositoryProvider));
});

/// Provides the [RiderNotifier] for rider feature screens.
final riderFeatureProvider =
    StateNotifierProvider<RiderNotifier, RiderFeatureState>((ref) {
  return RiderNotifier(
    getTodayTasksUseCase: ref.watch(getTodayTasksUseCaseProvider),
    gpsCheckinUseCase: ref.watch(gpsCheckinUseCaseProvider),
    completeTaskUseCase: ref.watch(completeTaskUseCaseProvider),
    repository: ref.watch(riderRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Rider notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing rider feature UI state.
class RiderNotifier extends StateNotifier<RiderFeatureState> {
  final GetTodayTasksUseCase _getTodayTasksUseCase;
  final GpsCheckinUseCase _gpsCheckinUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final RiderRepository _repository;

  RiderNotifier({
    required GetTodayTasksUseCase getTodayTasksUseCase,
    required GpsCheckinUseCase gpsCheckinUseCase,
    required CompleteTaskUseCase completeTaskUseCase,
    required RiderRepository repository,
  })  : _getTodayTasksUseCase = getTodayTasksUseCase,
        _gpsCheckinUseCase = gpsCheckinUseCase,
        _completeTaskUseCase = completeTaskUseCase,
        _repository = repository,
        super(const RiderInitial());

  /// Load today's tasks with optional type filter.
  Future<void> loadTodayTasks({String? type}) async {
    state = const RiderLoading();

    final result = await _getTodayTasksUseCase(
      GetTodayTasksParams(type: type),
    );

    state = result.fold(
      (failure) => RiderError(failure.message, failure: failure),
      (tasks) => RiderTasksLoaded(
        tasks: tasks,
        activeFilter: type,
      ),
    );
  }

  /// Perform GPS check-in for a task.
  Future<void> gpsCheckin({
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _gpsCheckinUseCase(
      GpsCheckinParams(
        taskId: taskId,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    state = result.fold(
      (failure) => RiderError(failure.message, failure: failure),
      (task) => GpsCheckinResult(task: task, success: true),
    );
  }

  /// Mark a task as delivered.
  Future<void> markDelivered({
    required String taskId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    final result = await _completeTaskUseCase(
      CompleteTaskParams(
        taskId: taskId,
        completionType: TaskCompletionType.delivered,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      ),
    );

    state = result.fold(
      (failure) => RiderError(failure.message, failure: failure),
      (task) => TaskCompleted(
        task: task,
        message: 'Cash delivered successfully.',
      ),
    );
  }

  /// Mark a task as collected.
  Future<void> markCollected({
    required String taskId,
    required double amount,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    final result = await _completeTaskUseCase(
      CompleteTaskParams(
        taskId: taskId,
        completionType: TaskCompletionType.collected,
        amount: amount,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      ),
    );

    state = result.fold(
      (failure) => RiderError(failure.message, failure: failure),
      (task) => TaskCompleted(
        task: task,
        message: 'Payment collected successfully.',
      ),
    );
  }

  /// Load task history with optional date range.
  Future<void> loadHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const RiderLoading();
    }

    final result = await _repository.getHistory(
      startDate: startDate,
      endDate: endDate,
      page: page,
    );

    state = result.fold(
      (failure) => RiderError(failure.message, failure: failure),
      (tasks) {
        final existingTasks = state is RiderHistoryLoaded && page > 1
            ? (state as RiderHistoryLoaded).tasks
            : <RiderTask>[];
        return RiderHistoryLoaded(
          tasks: [...existingTasks, ...tasks],
          page: page,
          hasMore: tasks.length >= 20,
        );
      },
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const RiderInitial();
  }
}
