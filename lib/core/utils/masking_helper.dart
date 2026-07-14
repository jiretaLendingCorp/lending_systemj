// lib/core/utils/masking_helper.dart
class MaskingHelper {
  MaskingHelper._();

  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return '*' * digits.length;
    }
    final visibleStart = digits.substring(0, 4);
    final visibleEnd = digits.substring(digits.length - 4);
    final maskedMiddle = '*' * (digits.length - 8);
    return '$visibleStart$maskedMiddle$visibleEnd';
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';

    final local = parts[0];
    final domain = parts[1];

    if (local.length <= 2) {
      return '$local***@$domain';
    }

    final first = local[0];
    final last = local[local.length - 1];
    final masked = '*' * (local.length - 2);

    return '$first$masked$last@$domain';
  }

  static String maskName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((part) {
      if (part.isEmpty) return part;
      return '${part[0]}${"*" * (part.length - 1)}';
    }).join(' ');
  }

  static String maskReference(String ref) {
    if (ref.length <= 8) return ref;
    final visibleStart = ref.substring(0, 4);
    final visibleEnd = ref.substring(ref.length - 4);
    final maskedMiddle = '*' * (ref.length - 8);
    return '$visibleStart$maskedMiddle$visibleEnd';
  }

  static String maskGovId(String id) {
    final digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '****';
    return '*${digits.substring(digits.length - 4)}';
  }

  static String maskBankAccount(String account) {
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '****';
    return '*${digits.substring(digits.length - 4)}';
  }

  static String maskAddress(String address) {
    final parts = address.split(',');
    if (parts.length <= 1) return '***';
    return '***, ${parts.sublist(1).join(',').trim()}';
  }

  static String maskGeneric(
    String value, {
    int visibleStart = 2,
    int visibleEnd = 2,
  }) {
    if (value.length <= visibleStart + visibleEnd) {
      return '*' * value.length;
    }
    final start = value.substring(0, visibleStart);
    final end = value.substring(value.length - visibleEnd);
    final masked = '*' * (value.length - visibleStart - visibleEnd);
    return '$start$masked$end';
  }
}
