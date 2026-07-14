import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/settings/domain/entities/system_settings.dart';

/// Abstract repository for system settings operations.
///
/// Sensitive operations (interest rate, penalty rate changes)
/// require a [reAuthToken] obtained through forced re-authentication.
abstract class SettingsRepository {
  /// Fetch the current system settings.
  Future<Either<Failure, SystemSettings>> get();

  /// Update system settings (general update).
  Future<Either<Failure, SystemSettings>> update({
    required Map<String, dynamic> data,
    String? reAuthToken,
  });

  /// Update interest rate (requires re-auth).
  Future<Either<Failure, SystemSettings>> updateInterestRate({
    required double interestRate,
    required String reAuthToken,
  });

  /// Update penalty rate (requires re-auth).
  Future<Either<Failure, SystemSettings>> updatePenaltyRate({
    required double penaltyRate,
    required int penaltyThresholdDays,
    required String reAuthToken,
  });

  /// Update SMS template.
  Future<Either<Failure, SystemSettings>> updateSmsTemplate({
    required String smsTemplate,
  });

  /// Update notification preferences.
  Future<Either<Failure, SystemSettings>> updateNotificationPreferences({
    required Map<String, dynamic> preferences,
  });

  /// Update system flags.
  Future<Either<Failure, SystemSettings>> updateSystemFlags({
    required Map<String, dynamic> flags,
    String? reAuthToken,
  });
}
