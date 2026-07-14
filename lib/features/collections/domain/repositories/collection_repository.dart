import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/collections/domain/entities/collection.dart';

/// Abstract interface for collection operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class CollectionRepository {
  /// List collections with optional filters and pagination.
  Future<Either<Failure, CollectionListResult>> list({
    String? status,
    String? method,
    String? riderId,
    String? borrowerId,
    String? date,
    int page = 1,
    int pageSize = 20,
  });

  /// Get detailed information about a specific collection.
  Future<Either<Failure, Collection>> detail(String collectionId);

  /// Assign a rider to a collection (manager/admin).
  Future<Either<Failure, Collection>> assignRider({
    required String collectionId,
    required String riderId,
  });

  /// Mark a collection as collected (rider action).
  ///
  /// Requires GPS coordinates from the rider's device.
  Future<Either<Failure, Collection>> markCollected({
    required String collectionId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  });

  /// Mark a collection as partially collected.
  Future<Either<Failure, Collection>> markPartial({
    required String collectionId,
    required double collectedAmount,
    required double latitude,
    required double longitude,
  });

  /// Mark a collection as failed.
  Future<Either<Failure, Collection>> markFailed(
    String collectionId, {
    String? reason,
  });

  /// Get available riders for assignment.
  Future<Either<Failure, List<CollectionRiderInfo>>> getAvailableRiders();
}

/// Paginated result for collection list queries.
class CollectionListResult {
  final List<Collection> collections;
  final int total;

  const CollectionListResult({
    required this.collections,
    required this.total,
  });
}

/// Simplified rider info for collection assignment.
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
