// lib/features/collections/presentation/providers/collection_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/collections/data/datasources/collection_remote_datasource.dart';
import 'package:jireta_loan/features/collections/data/repositories/collection_repository_impl.dart';
import 'package:jireta_loan/features/collections/domain/entities/collection.dart';
import 'package:jireta_loan/features/collections/domain/repositories/collection_repository.dart';
import 'package:jireta_loan/features/collections/domain/usecases/assign_rider_collection_usecase.dart';
import 'package:jireta_loan/features/collections/domain/usecases/mark_collected_usecase.dart';


sealed class CollectionFeatureState {
  const CollectionFeatureState();
}

class CollectionInitial extends CollectionFeatureState {
  const CollectionInitial();
}

class CollectionsLoading extends CollectionFeatureState {
  const CollectionsLoading();
}

class CollectionsLoaded extends CollectionFeatureState {
  final List<Collection> collections;
  final int total;
  final String? activeStatusFilter;
  final String? activeMethodFilter;
  final int currentPage;

  const CollectionsLoaded({
    required this.collections,
    required this.total,
    this.activeStatusFilter,
    this.activeMethodFilter,
    this.currentPage = 1,
  });

  bool get hasMore => collections.length < total;
}

class CollectionDetailLoaded extends CollectionFeatureState {
  final Collection collection;

  const CollectionDetailLoaded({required this.collection});
}

class CollectionOperationSuccess extends CollectionFeatureState {
  final Collection collection;
  final String message;

  const CollectionOperationSuccess({
    required this.collection,
    required this.message,
  });
}

class CollectionError extends CollectionFeatureState {
  final String message;
  final Failure? failure;

  const CollectionError(this.message, {this.failure});
}


final collectionRemoteDataSourceProvider =
    Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSource(dio: ref.watch(dioProvider));
});

final collectionRepositoryProvider =
    Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(
    remoteDataSource: ref.watch(collectionRemoteDataSourceProvider),
  );
});

final assignRiderCollectionUseCaseProvider =
    Provider<AssignRiderCollectionUseCase>((ref) {
  return AssignRiderCollectionUseCase(
    repository: ref.watch(collectionRepositoryProvider),
  );
});

final markCollectedUseCaseProvider =
    Provider<MarkCollectedUseCase>((ref) {
  return MarkCollectedUseCase(
    repository: ref.watch(collectionRepositoryProvider),
  );
});

final collectionFeatureProvider = StateNotifierProvider<
    CollectionNotifier, CollectionFeatureState>((ref) {
  return CollectionNotifier(
    assignRiderUseCase: ref.watch(assignRiderCollectionUseCaseProvider),
    markCollectedUseCase: ref.watch(markCollectedUseCaseProvider),
    repository: ref.watch(collectionRepositoryProvider),
  );
});

final collectionUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AppAuthAuthenticated) {
    return authState.role;
  }
  return null;
});


class CollectionNotifier
    extends StateNotifier<CollectionFeatureState> {
  final AssignRiderCollectionUseCase _assignRiderUseCase;
  final MarkCollectedUseCase _markCollectedUseCase;
  final CollectionRepository _repository;

  CollectionNotifier({
    required AssignRiderCollectionUseCase assignRiderUseCase,
    required MarkCollectedUseCase markCollectedUseCase,
    required CollectionRepository repository,
  })  : _assignRiderUseCase = assignRiderUseCase,
        _markCollectedUseCase = markCollectedUseCase,
        _repository = repository,
        super(const CollectionInitial());

  Future<void> loadCollections({
    String? status,
    String? method,
    String? riderId,
    String? lenderId,
    String? date,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const CollectionsLoading();
    }

    final result = await _repository.list(
      status: status,
      method: method,
      riderId: riderId,
      lenderId: lenderId,
      date: date,
      page: page,
    );

    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (listResult) {
        final existing = state is CollectionsLoaded && page > 1
            ? (state as CollectionsLoaded).collections
            : <Collection>[];
        return CollectionsLoaded(
          collections: [...existing, ...listResult.collections],
          total: listResult.total,
          activeStatusFilter: status,
          activeMethodFilter: method,
          currentPage: page,
        );
      },
    );
  }

  Future<void> loadMore({String? riderId}) async {
    if (state is! CollectionsLoaded) return;
    final current = state as CollectionsLoaded;
    if (!current.hasMore) return;

    await loadCollections(
      status: current.activeStatusFilter,
      method: current.activeMethodFilter,
      riderId: riderId,
      page: current.currentPage + 1,
    );
  }

  Future<void> loadCollectionDetail(String collectionId) async {
    state = const CollectionsLoading();

    final result = await _repository.detail(collectionId);
    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (collection) =>
          CollectionDetailLoaded(collection: collection),
    );
  }

  Future<void> assignRider({
    required String collectionId,
    required String riderId,
  }) async {
    final result = await _assignRiderUseCase(
      AssignRiderCollectionParams(
        collectionId: collectionId,
        riderId: riderId,
      ),
    );

    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (collection) => CollectionOperationSuccess(
        collection: collection as Collection,
        message: 'Rider assigned to collection successfully.',
      ),
    );
  }

  Future<void> markCollected({
    required String collectionId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    final result = await _markCollectedUseCase(
      MarkCollectedParams(
        collectionId: collectionId,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      ),
    );

    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (collection) => CollectionOperationSuccess(
        collection: collection as Collection,
        message: 'Collection marked as collected.',
      ),
    );
  }

  Future<void> markFailed(String collectionId, {String? reason}) async {
    final result =
        await _repository.markFailed(collectionId, reason: reason);
    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (collection) => CollectionOperationSuccess(
        collection: collection,
        message: 'Collection marked as failed.',
      ),
    );
  }

  Future<void> loadTodayCollections(String riderId) async {
    state = const CollectionsLoading();

    final result = await _repository.list(
      riderId: riderId,
      status: 'assigned,in_transit',
    );

    state = result.fold(
      (failure) =>
          CollectionError(failure.message, failure: failure),
      (listResult) => CollectionsLoaded(
        collections: listResult.collections,
        total: listResult.total,
      ),
    );
  }

  void resetState() {
    state = const CollectionInitial();
  }
}
