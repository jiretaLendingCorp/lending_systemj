// lib/features/loans/data/models/create_loan_request.dart
import 'package:equatable/equatable.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';

class CreateLoanRequest extends Equatable {
  final double principal;
  final int termDays;
  final ScheduleType scheduleType;
  final String coMakerFullName;
  final String coMakerPhone;
  final String coMakerAddress;
  final String coMakerRelationship;

  const CreateLoanRequest({
    required this.principal,
    required this.termDays,
    this.scheduleType = ScheduleType.monthly,
    required this.coMakerFullName,
    required this.coMakerPhone,
    required this.coMakerAddress,
    required this.coMakerRelationship,
  });

  Map<String, dynamic> toJson() {
    return {
      'principal': principal,
      'term_days': termDays,
      'schedule_type': scheduleType.toApiString(),
      'co_maker': {
        'full_name': coMakerFullName,
        'phone': coMakerPhone,
        'address': coMakerAddress,
        'relationship': coMakerRelationship,
      },
    };
  }

  @override
  List<Object?> get props => [
        principal,
        termDays,
        scheduleType,
        coMakerFullName,
        coMakerPhone,
        coMakerAddress,
        coMakerRelationship,
      ];
}
