// lib/features/payments/data/models/payment_model.dart
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.loanId,
    required super.lenderId,
    required super.amount,
    super.method = PaymentMethod.cash,
    super.status = PaymentStatus.pending,
    super.referenceNumber,
    super.xenditPaymentId,
    super.collectedBy,
    super.collectedAt,
    super.receiptUrl,
    required super.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      lenderId:
          json['lender_id'] as String? ?? json['lenderId'] as String? ?? '',
      amount: _parseDouble(json['amount']),
      method: PaymentMethod.fromString(
        json['method'] as String? ?? json['payment_method'] as String?,
      ),
      status: PaymentStatus.fromString(json['status'] as String?),
      referenceNumber: json['reference_number'] as String? ??
          json['referenceNumber'] as String?,
      xenditPaymentId: json['xendit_payment_id'] as String? ??
          json['xenditPaymentId'] as String?,
      collectedBy: json['collected_by'] as String? ??
          json['collectedBy'] as String?,
      collectedAt: _parseDateTime(
          json['collected_at'] ?? json['collectedAt']),
      receiptUrl:
          json['receipt_url'] as String? ?? json['receiptUrl'] as String?,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'lender_id': lenderId,
      'amount': amount,
      'method': method.toApiString(),
      'status': status.toApiString(),
      'reference_number': referenceNumber,
      'xendit_payment_id': xenditPaymentId,
      'collected_by': collectedBy,
      'collected_at': collectedAt?.toIso8601String(),
      'receipt_url': receiptUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? loanId,
    String? lenderId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? referenceNumber,
    String? xenditPaymentId,
    String? collectedBy,
    DateTime? collectedAt,
    String? receiptUrl,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      lenderId: lenderId ?? this.lenderId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      xenditPaymentId: xenditPaymentId ?? this.xenditPaymentId,
      collectedBy: collectedBy ?? this.collectedBy,
      collectedAt: collectedAt ?? this.collectedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
    );
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
