// lib/core/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

class TextStyles {
  TextStyles._();

  static TextStyle displayLarge(BuildContext context) => TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle displayMedium(BuildContext context) => TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle displaySmall(BuildContext context) => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle headlineLarge(BuildContext context) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle headlineMedium(BuildContext context) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle headlineSmall(BuildContext context) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle titleLarge(BuildContext context) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        letterSpacing: 0,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle titleMedium(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        letterSpacing: 0.15,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle titleSmall(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle bodyLarge(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: 0.50,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle bodySmall(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.40,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightTextSecondary
            : ColorTokens.darkTextSecondary,
      );

  static TextStyle labelLarge(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightText
            : ColorTokens.darkText,
      );

  static TextStyle labelMedium(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.50,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightTextSecondary
            : ColorTokens.darkTextSecondary,
      );

  static TextStyle labelSmall(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.50,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightTextSecondary
            : ColorTokens.darkTextSecondary,
      );

  static TextStyle accentLabel(BuildContext context) => labelLarge(context).copyWith(
        color: ColorTokens.accent,
      );

  static TextStyle secondaryAccentLabel(BuildContext context) =>
      labelLarge(context).copyWith(
        color: ColorTokens.secondaryAccent,
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.40,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightTextSecondary
            : ColorTokens.darkTextSecondary,
      );

  static TextStyle overline(BuildContext context) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.60,
        letterSpacing: 1.50,
        color: Theme.of(context).brightness == Brightness.light
            ? ColorTokens.lightTextSecondary
            : ColorTokens.darkTextSecondary,
      );

  static TextStyle button(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.10,
        color: Colors.white,
      );
}
