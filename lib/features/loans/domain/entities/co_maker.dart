import 'package:equatable/equatable.dart';

/// Co-maker (guarantor) entity for a loan application.
///
/// A co-maker is a person who agrees to be responsible for the
/// loan repayment if the borrower defaults. Philippine lending
/// regulations typically require a co-maker for micro-finance loans.
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

  /// Whether the co-maker has given consent.
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
