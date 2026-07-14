import 'package:flutter/material.dart';

/// Centralized color tokens for the LendFlow design system.
///
/// All feature code must reference these tokens — never hard-code hex literals.
class ColorTokens {
  ColorTokens._();

  // ── Light palette ──────────────────────────────────────────────
  static const Color lightCanvas = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A2332);
  static const Color lightTextSecondary = Color(0xFF5F6B7A);
  static const Color lightSurface = Color(0xFFF7F8FA);
  static const Color lightBorder = Color(0xFFE2E5E9);
  static const Color lightDisabled = Color(0xFFB0B8C4);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF2E7D32);
  static const Color lightWarning = Color(0xFFF57C00);
  static const Color lightInfo = Color(0xFF1976D2);

  // ── Dark palette ───────────────────────────────────────────────
  static const Color darkCanvas = Color(0xFF0A0B0B);
  static const Color darkText = Color(0xFFE9EAEB);
  static const Color darkTextSecondary = Color(0xFF9BA4AE);
  static const Color darkSurface = Color(0xFF141617);
  static const Color darkBorder = Color(0xFF2A2D2E);
  static const Color darkDisabled = Color(0xFF4A4F54);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkWarning = Color(0xFFFFA726);
  static const Color darkInfo = Color(0xFF42A5F5);

  // ── Accent colours (shared between themes) ─────────────────────
  static const Color accent = Color(0xFF4CA5D2); // Cyan
  static const Color accentLight = Color(0xFF7DBDE3);
  static const Color accentDark = Color(0xFF3A8BB8);
  static const Color secondaryAccent = Color(0xFFC3603F); // Warm orange
  static const Color secondaryAccentLight = Color(0xFFD4805F);
  static const Color secondaryAccentDark = Color(0xFFA44E30);

  // ── Semantic colours ───────────────────────────────────────────
  static const Color loanActive = Color(0xFF4CA5D2);
  static const Color loanOverdue = Color(0xFFD32F2F);
  static const Color loanPaid = Color(0xFF2E7D32);
  static const Color loanPending = Color(0xFFF57C00);

  static const Color statusApproved = Color(0xFF2E7D32);
  static const Color statusRejected = Color(0xFFD32F2F);
  static const Color statusPending = Color(0xFFF57C00);

  // ── Role colours ───────────────────────────────────────────────
  static const Color roleAdmin = Color(0xFF6A1B9A);
  static const Color roleManager = Color(0xFF1565C0);
  static const Color roleRider = Color(0xFF2E7D32);
  static const Color roleBorrower = Color(0xFF4CA5D2);
}
