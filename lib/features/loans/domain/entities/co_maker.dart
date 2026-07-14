// lib/features/loans/domain/entities/co_maker.dart
import 'package:equatable/equatable.dart';

class CoMaker extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String relationship;
  final DateTime? consentAt;

  const CoMaker({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.relationship,
    this.consentAt,
  });

  bool get hasConsented => consentAt != null;

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        address,
        relationship,
        consentAt,
      ];
}
