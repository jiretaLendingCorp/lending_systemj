import 'package:lendflow/features/settings/domain/entities/system_settings.dart';

/// Data-layer representation of [SystemSettings], with JSON serialization.
class SystemSettingsModel extends SystemSettings {
  const SystemSettingsModel({
    required super.id,
    super.interestRate = 0.20,
    super.penaltyRate = 0.20,
    super.penaltyThresholdDays = 3,
    super.smsTemplate =
        'Hi {borrower_name}, your payment of {amount} is due on {due_date}. - LendFlow',
    super.notificationPreferences = const NotificationPreferences(),
    super.systemFlags = const SystemFlags(),
    required super.updatedAt,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      id: json['id'] as String,
      interestRate: _parseDouble(json['interest_rate'] ?? json['interestRate'], fallback: 0.20),
      penaltyRate: _parseDouble(json['penalty_rate'] ?? json['penaltyRate'], fallback: 0.20),
      penaltyThresholdDays: json['penalty_threshold_days'] as int? ??
          json['penaltyThresholdDays'] as int? ??
          3,
      smsTemplate: json['sms_template'] as String? ??
          json['smsTemplate'] as String? ??
          'Hi {borrower_name}, your payment of {amount} is due on {due_date}. - LendFlow',
      notificationPreferences: _parseNotificationPrefs(
        json['notification_preferences'] ?? json['notificationPreferences'],
      ),
      systemFlags: _parseSystemFlags(
        json['system_flags'] ?? json['systemFlags'],
      ),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interest_rate': interestRate,
      'penalty_rate': penaltyRate,
      'penalty_threshold_days': penaltyThresholdDays,
      'sms_template': smsTemplate,
      'notification_preferences': {
        'email_notifications': notificationPreferences.emailNotifications,
        'sms_notifications': notificationPreferences.smsNotifications,
        'push_notifications': notificationPreferences.pushNotifications,
        'overdue_alerts': notificationPreferences.overdueAlerts,
        'payment_reminders': notificationPreferences.paymentReminders,
        'system_alerts': notificationPreferences.systemAlerts,
      },
      'system_flags': {
        'maintenance_mode': systemFlags.maintenanceMode,
        'allow_new_registrations': systemFlags.allowNewRegistrations,
        'allow_loan_applications': systemFlags.allowLoanApplications,
        'auto_approve_loans': systemFlags.autoApproveLoans,
        'enforce_kyc_verification': systemFlags.enforceKycVerification,
        'disable_overdue_penalty': systemFlags.disableOverduePenalty,
      },
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SystemSettingsModel copyWith({
    String? id,
    double? interestRate,
    double? penaltyRate,
    int? penaltyThresholdDays,
    String? smsTemplate,
    NotificationPreferences? notificationPreferences,
    SystemFlags? systemFlags,
    DateTime? updatedAt,
  }) {
    return SystemSettingsModel(
      id: id ?? this.id,
      interestRate: interestRate ?? this.interestRate,
      penaltyRate: penaltyRate ?? this.penaltyRate,
      penaltyThresholdDays: penaltyThresholdDays ?? this.penaltyThresholdDays,
      smsTemplate: smsTemplate ?? this.smsTemplate,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      systemFlags: systemFlags ?? this.systemFlags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static NotificationPreferences _parseNotificationPrefs(dynamic value) {
    if (value is Map<String, dynamic>) {
      return NotificationPreferences(
        emailNotifications: value['email_notifications'] as bool? ?? true,
        smsNotifications: value['sms_notifications'] as bool? ?? true,
        pushNotifications: value['push_notifications'] as bool? ?? true,
        overdueAlerts: value['overdue_alerts'] as bool? ?? true,
        paymentReminders: value['payment_reminders'] as bool? ?? true,
        systemAlerts: value['system_alerts'] as bool? ?? true,
      );
    }
    return const NotificationPreferences();
  }

  static SystemFlags _parseSystemFlags(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SystemFlags(
        maintenanceMode: value['maintenance_mode'] as bool? ?? false,
        allowNewRegistrations: value['allow_new_registrations'] as bool? ?? true,
        allowLoanApplications: value['allow_loan_applications'] as bool? ?? true,
        autoApproveLoans: value['auto_approve_loans'] as bool? ?? false,
        enforceKycVerification: value['enforce_kyc_verification'] as bool? ?? true,
        disableOverduePenalty: value['disable_overdue_penalty'] as bool? ?? false,
      );
    }
    return const SystemFlags();
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
