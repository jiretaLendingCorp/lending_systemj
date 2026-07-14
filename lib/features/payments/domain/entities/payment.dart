// lib/features/payments/domain/entities/payment.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PaymentMethod {
  gcash,
  office,
  cash;

  static PaymentMethod fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'gcash' => PaymentMethod.gcash,
      'office' => PaymentMethod.office,
      'cash' => PaymentMethod.cash,
      _ => PaymentMethod.cash,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        PaymentMethod.gcash => 'GCash',
        PaymentMethod.office => 'Office',
        PaymentMethod.cash => 'Cash (Rider)',
      };

  String get description => switch (this) {
        PaymentMethod.gcash => 'Pay via GCash through Xendit',
        PaymentMethod.office => 'Pay at the branch office',
        PaymentMethod.cash => 'Cash pickup by a rider',
      };

  IconData get iconData => switch (this) {
        PaymentMethod.gcash => Icons.phone_android_rounded,
        PaymentMethod.office => Icons.store_rounded,
        PaymentMethod.cash => Icons.payments_rounded,
      };
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  static PaymentStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'pending' => PaymentStatus.pending,
      'completed' => PaymentStatus.completed,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        PaymentStatus.pending => 'Pending',
        PaymentStatus.completed => 'Completed',
        PaymentStatus.failed => 'Failed',
        PaymentStatus.refunded => 'Refunded',
      };

  bool get isTerminal =>
      this == PaymentStatus.completed ||
      this == PaymentStatus.failed ||
      this == PaymentStatus.refunded;
}

class Payment extends Equatable {
  final String id;
  final String loanId;
  final String lenderId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? referenceNumber;
  final String? xenditPaymentId;
  final String? collectedBy;
  final DateTime? collectedAt;
  final String? receiptUrl;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.loanId,
    required this.lenderId,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.status = PaymentStatus.pending,
    this.referenceNumber,
    this.xenditPaymentId,
    this.collectedBy,
    this.collectedAt,
    this.receiptUrl,
    required this.createdAt,
  });

  bool get isGcash => method == PaymentMethod.gcash;

  bool get isOffice => method == PaymentMethod.office;

  bool get isCashCollection => method == PaymentMethod.cash;

  bool get isInProgress => status == PaymentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        loanId,
        lenderId,
        amount,
        method,
        status,
        referenceNumber,
        xenditPaymentId,
        collectedBy,
        collectedAt,
        receiptUrl,
        createdAt,
      ];
}
