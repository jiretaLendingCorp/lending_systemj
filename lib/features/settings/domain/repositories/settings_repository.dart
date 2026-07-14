// lib/features/settings/domain/repositories/settings_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/settings/domain/entities/system_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, SystemSettings>> get();

  Future<Either<Failure, SystemSettings>> update({
    required Map<String, dynamic> data,
    String? reAuthToken,
  });

  Future<Either<Failure, SystemSettings>> updateInterestRate({
    required double interestRate,
    required String reAuthToken,
  });

  Future<Either<Failure, SystemSettings>> updatePenaltyRate({
    required double penaltyRate,
    required int penaltyThresholdDays,
    required String reAuthToken,
  });

  Future<Either<Failure, SystemSettings>> updateSmsTemplate({
    required String smsTemplate,
  });

  Future<Either<Failure, SystemSettings>> updateNotificationPreferences({
    required Map<String, dynamic> preferences,
  });

  Future<Either<Failure, SystemSettings>> updateSystemFlags({
    required Map<String, dynamic> flags,
    String? reAuthToken,
  });
}
