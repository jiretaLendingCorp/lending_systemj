// lib/features/settings/presentation/providers/settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:jireta_loan/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:jireta_loan/features/settings/domain/entities/system_settings.dart';
import 'package:jireta_loan/features/settings/domain/repositories/settings_repository.dart';

sealed class SettingsFeatureState {
  const SettingsFeatureState();
}

class SettingsInitial extends SettingsFeatureState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsFeatureState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsFeatureState {
  final SystemSettings settings;

  const SettingsLoaded({required this.settings});
}

class SettingsUpdateSuccess extends SettingsFeatureState {
  final SystemSettings settings;
  final String message;

  const SettingsUpdateSuccess({
    required this.settings,
    required this.message,
  });
}

class SettingsError extends SettingsFeatureState {
  final String message;
  final Failure? failure;

  const SettingsError(this.message, {this.failure});
}

final settingsRemoteDataSourceProvider =
    Provider<SettingsRemoteDataSource>((ref) {
  return SettingsRemoteDataSource(dio: ref.watch(dioProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    remoteDataSource: ref.watch(settingsRemoteDataSourceProvider),
  );
});

final settingsFeatureProvider =
    StateNotifierProvider<SettingsNotifier, SettingsFeatureState>((ref) {
  return SettingsNotifier(
    repository: ref.watch(settingsRepositoryProvider),
  );
});

class SettingsNotifier extends StateNotifier<SettingsFeatureState> {
  final SettingsRepository _repository;

  SettingsNotifier({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(const SettingsInitial());

  Future<void> loadSettings() async {
    state = const SettingsLoading();

    final result = await _repository.get();

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsLoaded(settings: settings),
    );
  }

  Future<void> updateInterestRate({
    required double interestRate,
    required String reAuthToken,
  }) async {
    final result = await _repository.updateInterestRate(
      interestRate: interestRate,
      reAuthToken: reAuthToken,
    );

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsUpdateSuccess(
        settings: settings,
        message: 'Interest rate updated to ${(interestRate * 100).toStringAsFixed(1)}%.',
      ),
    );
  }

  Future<void> updatePenaltyRate({
    required double penaltyRate,
    required int penaltyThresholdDays,
    required String reAuthToken,
  }) async {
    final result = await _repository.updatePenaltyRate(
      penaltyRate: penaltyRate,
      penaltyThresholdDays: penaltyThresholdDays,
      reAuthToken: reAuthToken,
    );

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsUpdateSuccess(
        settings: settings,
        message: 'Penalty settings updated.',
      ),
    );
  }

  Future<void> updateSmsTemplate({required String smsTemplate}) async {
    final result = await _repository.updateSmsTemplate(
      smsTemplate: smsTemplate,
    );

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsUpdateSuccess(
        settings: settings,
        message: 'SMS template updated.',
      ),
    );
  }

  Future<void> updateNotificationPreferences({
    required Map<String, dynamic> preferences,
  }) async {
    final result = await _repository.updateNotificationPreferences(
      preferences: preferences,
    );

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsUpdateSuccess(
        settings: settings,
        message: 'Notification preferences updated.',
      ),
    );
  }

  Future<void> updateSystemFlags({
    required Map<String, dynamic> flags,
    String? reAuthToken,
  }) async {
    final result = await _repository.updateSystemFlags(
      flags: flags,
      reAuthToken: reAuthToken,
    );

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsUpdateSuccess(
        settings: settings,
        message: 'System flags updated.',
      ),
    );
  }

  void resetState() {
    state = const SettingsInitial();
  }
}
