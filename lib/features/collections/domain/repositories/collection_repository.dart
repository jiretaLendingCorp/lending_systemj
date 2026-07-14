// lib/features/collections/domain/repositories/collection_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/collections/domain/entities/collection.dart';

abstract class CollectionRepository {
  Future<Either<Failure, CollectionListResult>> list({
    String? status,
    String? method,
    String? riderId,
    String? lenderId,
    String? date,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, Collection>> detail(String collectionId);

  Future<Either<Failure, Collection>> assignRider({
    required String collectionId,
    required String riderId,
  });

  Future<Either<Failure, Collection>> markCollected({
    required String collectionId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  Future<Either<Failure, Collection>> markPartial({
    required String collectionId,
    required double collectedAmount,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, Collection>> markFailed(
    String collectionId, {
    String? reason,
  });

  Future<Either<Failure, List<CollectionRiderInfo>>> getAvailableRiders();
}

class CollectionListResult {
  final List<Collection> collections;
  final int total;

  const CollectionListResult({
    required this.collections,
    required this.total,
  });
}

class CollectionRiderInfo {
  final String id;
  final String name;
  final String? phone;
  final bool isAvailable;
  final int activeCollections;

  const CollectionRiderInfo({
    required this.id,
    required this.name,
    this.phone,
    this.isAvailable = true,
    this.activeCollections = 0,
  });
}
