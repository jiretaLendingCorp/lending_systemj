// lib/features/auth/presentation/widgets/google_sign_in_button.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

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
    if (kIsWeb) {
      return _buildWebButton(context, isDark);
    }
    return _buildMobileButton(context, isDark);
  }

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
            borderRadius: BorderRadius.circular(12),
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
                  const _GoogleLogoAsset(size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMobileButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
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
            : const _GoogleLogoAsset(size: 22),
        label: Text(
          isLoading ? 'Signing in...' : 'Continue with Google',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? ColorTokens.darkSurface : Colors.white,
          side: BorderSide(
            color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoAsset extends StatelessWidget {
  final double size;
  const _GoogleLogoAsset({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
