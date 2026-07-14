import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';

/// Google Sign-In button widget.
///
/// Renders a platform-appropriate Google OAuth button:
/// - On web: uses a standard "Sign in with Google" button style
/// - On mobile: uses the Google icon + label layout
///
/// The button handles its own loading state when [isLoading] is true.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeb = kIsWeb;

    if (isWeb) {
      return _buildWebButton(context, isDark);
    }
    return _buildMobileButton(context, isDark);
  }

  /// Web-style Google Sign-In button with Google's branded colors.
  Widget _buildWebButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? ColorTokens.darkSurface : Colors.white,
          side: BorderSide(
            color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo
                  _GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? ColorTokens.darkText
                          : ColorTokens.lightText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Mobile-style Google Sign-In button.
  Widget _buildMobileButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: enabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
                ),
              )
            : _GoogleLogo(size: 20),
        label: Text(
          isLoading ? 'Signing in...' : 'Continue with Google',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? ColorTokens.darkSurface : Colors.white,
          side: BorderSide(
            color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// Simplified Google "G" logo widget.
///
/// Uses a custom painter to draw a recognizable "G" icon
/// that matches Google's brand colors, avoiding the need
/// for an external SVG asset.
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the colored segments of the Google G
    final strokeWidth = size.width * 0.12;

    // Blue segment (top-right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -1.2,
      1.4,
      false,
      bluePaint,
    );

    // Red segment (top)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -2.0,
      0.8,
      false,
      redPaint,
    );

    // Yellow segment (bottom-left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      0.6,
      1.0,
      false,
      yellowPaint,
    );

    // Green segment (bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      1.6,
      1.0,
      false,
      greenPaint,
    );

    // Draw the horizontal bar of the G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width - strokeWidth, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
