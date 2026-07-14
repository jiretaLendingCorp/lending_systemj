import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/audit_logs/domain/entities/audit_log.dart';

/// Abstract repository for audit log operations.
///
/// Audit logs are read-only — no create, update, or delete operations.
abstract class AuditLogRepository {
  /// List audit logs with optional filters and pagination.
  Future<Either<Failure, AuditLogListResult>> list({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  });

  /// Get a single audit log detail.
  Future<Either<Failure, AuditLog>> detail(String logId);

  /// Export audit logs as CSV.
  Future<Either<Failure, String>> export({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Paginated result for audit log list queries at the domain level.
class AuditLogListResult {
  final List<AuditLog> logs;
  final int total;

  const AuditLogListResult({
    required this.logs,
    required this.total,
  });
}
