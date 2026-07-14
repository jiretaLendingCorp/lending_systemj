// lib/features/notifications/domain/entities/app_notification.dart
import 'package:equatable/equatable.dart';

enum NotificationType {
  paymentReminder,
  loanApproved,
  loanRejected,
  disbursementRider,
  penaltyApplied,
  general;

  static NotificationType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'payment_reminder' => NotificationType.paymentReminder,
      'loan_approved' => NotificationType.loanApproved,
      'loan_rejected' => NotificationType.loanRejected,
      'disbursement_rider' => NotificationType.disbursementRider,
      'penalty_applied' => NotificationType.penaltyApplied,
      'general' => NotificationType.general,
      _ => NotificationType.general,
    };
  }

  String toApiString() => switch (this) {
        NotificationType.paymentReminder => 'payment_reminder',
        NotificationType.loanApproved => 'loan_approved',
        NotificationType.loanRejected => 'loan_rejected',
        NotificationType.disbursementRider => 'disbursement_rider',
        NotificationType.penaltyApplied => 'penalty_applied',
        NotificationType.general => 'general',
      };

  String get label => switch (this) {
        NotificationType.paymentReminder => 'Payment Reminder',
        NotificationType.loanApproved => 'Loan Approved',
        NotificationType.loanRejected => 'Loan Rejected',
        NotificationType.disbursementRider => 'Disbursement Update',
        NotificationType.penaltyApplied => 'Penalty Applied',
        NotificationType.general => 'General',
      };

  bool get isHighPriority => switch (this) {
        NotificationType.paymentReminder => true,
        NotificationType.loanApproved => true,
        NotificationType.loanRejected => true,
        NotificationType.penaltyApplied => true,
        NotificationType.disbursementRider => false,
        NotificationType.general => false,
      };
}

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.type = NotificationType.general,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        isRead,
        createdAt,
      ];
}
