import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:lendflow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:lendflow/features/settings/domain/entities/system_settings.dart';
import 'package:lendflow/features/settings/domain/repositories/settings_repository.dart';

// ─────────────────────────────────────────────────────────────────
// Settings state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level settings state.
sealed class SettingsFeatureState {
  const SettingsFeatureState();
}

/// Initial state.
class SettingsInitial extends SettingsFeatureState {
  const SettingsInitial();
}

/// Settings are being loaded.
class SettingsLoading extends SettingsFeatureState {
  const SettingsLoading();
}

/// Settings loaded successfully.
class SettingsLoaded extends SettingsFeatureState {
  final SystemSettings settings;

  const SettingsLoaded({required this.settings});
}

/// Settings update succeeded.
class SettingsUpdateSuccess extends SettingsFeatureState {
  final SystemSettings settings;
  final String message;

  const SettingsUpdateSuccess({
    required this.settings,
    required this.message,
  });
}

/// An error occurred.
class SettingsError extends SettingsFeatureState {
  final String message;
  final Failure? failure;

  const SettingsError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [SettingsRemoteDataSource].
final settingsRemoteDataSourceProvider =
    Provider<SettingsRemoteDataSource>((ref) {
  return SettingsRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [SettingsRepository] implementation.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    remoteDataSource: ref.watch(settingsRemoteDataSourceProvider),
  );
});

/// Provides the [SettingsNotifier] for settings screens.
final settingsFeatureProvider =
    StateNotifierProvider<SettingsNotifier, SettingsFeatureState>((ref) {
  return SettingsNotifier(
    repository: ref.watch(settingsRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Settings notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing settings UI state.
class SettingsNotifier extends StateNotifier<SettingsFeatureState> {
  final SettingsRepository _repository;

  SettingsNotifier({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(const SettingsInitial());

  /// Load the current system settings.
  Future<void> loadSettings() async {
    state = const SettingsLoading();

    final result = await _repository.get();

    state = result.fold(
      (failure) => SettingsError(failure.message, failure: failure),
      (settings) => SettingsLoaded(settings: settings),
    );
  }

  /// Update interest rate (requires re-auth token).
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

  /// Update penalty rate (requires re-auth token).
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

  /// Update SMS template (no re-auth required).
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

  /// Update notification preferences (no re-auth required).
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

  /// Update system flags (re-auth required for maintenance mode).
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

  /// Reset state to initial.
  void resetState() {
    state = const SettingsInitial();
  }
}
