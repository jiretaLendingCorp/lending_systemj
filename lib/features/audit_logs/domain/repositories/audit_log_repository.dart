// lib/features/audit_logs/domain/repositories/audit_log_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/audit_logs/domain/entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<Either<Failure, AuditLogListResult>> list({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, AuditLog>> detail(String logId);

  Future<Either<Failure, String>> export({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class AuditLogListResult {
  final List<AuditLog> logs;
  final int total;

  const AuditLogListResult({
    required this.logs,
    required this.total,
  });
}
