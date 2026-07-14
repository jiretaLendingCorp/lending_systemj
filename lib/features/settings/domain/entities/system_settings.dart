// lib/features/settings/domain/entities/system_settings.dart
import 'package:equatable/equatable.dart';

class SystemSettings extends Equatable {
  final String id;
  final double interestRate;
  final double penaltyRate;
  final int penaltyThresholdDays;
  final String smsTemplate;
  final NotificationPreferences notificationPreferences;
  final SystemFlags systemFlags;
  final DateTime updatedAt;

  const SystemSettings({
    required this.id,
    this.interestRate = 0.20,
    this.penaltyRate = 0.20,
    this.penaltyThresholdDays = 3,
    this.smsTemplate =
        'Hi {lender_name}, your payment of {amount} is due on {due_date}. - Jireta Loan',
    this.notificationPreferences = const NotificationPreferences(),
    this.systemFlags = const SystemFlags(),
    required this.updatedAt,
  });

  double get interestRatePercent => interestRate * 100;

  double get penaltyRatePercent => penaltyRate * 100;

  @override
  List<Object?> get props => [
        id,
        interestRate,
        penaltyRate,
        penaltyThresholdDays,
        smsTemplate,
        notificationPreferences,
        systemFlags,
        updatedAt,
      ];
}

class NotificationPreferences extends Equatable {
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool overdueAlerts;
  final bool paymentReminders;
  final bool systemAlerts;

  const NotificationPreferences({
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.pushNotifications = true,
    this.overdueAlerts = true,
    this.paymentReminders = true,
    this.systemAlerts = true,
  });

  @override
  List<Object?> get props => [
        emailNotifications,
        smsNotifications,
        pushNotifications,
        overdueAlerts,
        paymentReminders,
        systemAlerts,
      ];
}

class SystemFlags extends Equatable {
  final bool maintenanceMode;
  final bool allowNewRegistrations;
  final bool allowLoanApplications;
  final bool autoApproveLoans;
  final bool enforceKycVerification;
  final bool disableOverduePenalty;

  const SystemFlags({
    this.maintenanceMode = false,
    this.allowNewRegistrations = true,
    this.allowLoanApplications = true,
    this.autoApproveLoans = false,
    this.enforceKycVerification = true,
    this.disableOverduePenalty = false,
  });

  @override
  List<Object?> get props => [
        maintenanceMode,
        allowNewRegistrations,
        allowLoanApplications,
        autoApproveLoans,
        enforceKycVerification,
        disableOverduePenalty,
      ];
}
