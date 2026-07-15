// lib/core/theme/spacing_tokens.dart
import 'package:flutter/material.dart';

class Spacing {
  Spacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(16);

  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  );

  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);

  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
}

class Radii {
  Radii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xxl),
  );
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillShape = BorderRadius.all(Radius.circular(pill));
}

class AppElevation {
  AppElevation._();

  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;

  static List<BoxShadow> softShadow({
    required Color color,
    double opacity = 0.08,
    double blur = 16,
    double dy = 4,
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          offset: Offset(0, dy),
        ),
      ];

  static List<BoxShadow> layeredShadow({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);

  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutBack;
}
