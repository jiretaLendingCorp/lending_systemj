import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/validators.dart';
import 'package:lendflow/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lendflow/features/auth/presentation/widgets/auth_text_field.dart';

/// Forgot password page for requesting a password reset email.
///
/// After submitting their email, the user receives a Supabase
/// password reset link. The page shows a success state confirming
/// the email was sent.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authFeatureProvider.notifier).forgotPassword(
          email: _emailController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authFeatureProvider);
    final isLoading = authState is AuthLoading;
    final isPasswordResetSent = authState is AuthPasswordResetSent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthFeatureState>(authFeatureProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      }
    });

    Widget content;

    if (isPasswordResetSent) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.mark_email_read_rounded,
            size: 64,
            color: ColorTokens.lightSuccess,
          ),
          const SizedBox(height: 24),
          Text(
            'Check Your Email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
              children: [
                const TextSpan(
                    text: 'We sent a password reset link to\n'),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ColorTokens.darkText
                        : ColorTokens.lightText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The link will expire in 1 hour. If you don\'t see the email, check your spam folder.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSubmit,
            child: Text(
              'Didn\'t receive the email? Resend',
              style: TextStyle(
                color: ColorTokens.accent,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    } else {
      content = Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_reset_rounded,
              size: 48,
              color: ColorTokens.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your email and we\'ll send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email field
            AuthTextField(
              label: 'Email',
              hint: 'Enter your email address',
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
              prefixIcon: Icon(
                Icons.email_outlined,
                size: 20,
                color: isDark
                    ? ColorTokens.darkTextSecondary
                    : ColorTokens.lightTextSecondary,
              ),
              onEditingComplete: _handleSubmit,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleSubmit,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Reset Link'),
              ),
            ),
            const SizedBox(height: 24),

            // Back to login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: ColorTokens.accent,
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: ColorTokens.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isWeb) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? ColorTokens.darkBorder
                        : ColorTokens.lightBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: content,
        ),
      ),
    );
  }
}
