import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/validators.dart';
import 'package:lendflow/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lendflow/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:lendflow/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Login page with email/password fields, Google Sign-In, and forgot password.
///
/// Platform-aware: on web shows a centered card layout, on mobile
/// shows a full-screen scrollable layout.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authFeatureProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _handleGoogleSignIn() {
    ref.read(authFeatureProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authFeatureProvider);
    final isLoading = authState is AuthLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthFeatureState>(authFeatureProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      } else if (next is AuthAuthenticated) {
        // Auth state change will be handled by the core auth provider
        // which triggers the router redirect.
      }
    });

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo and welcome text
          Icon(
            Icons.account_balance_rounded,
            size: 48,
            color: ColorTokens.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your LendFlow account',
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
            hint: 'Enter your email',
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: () => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Password field
          AuthTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            prefixIcon: Icon(
              Icons.lock_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: _handleLogin,
          ),
          const SizedBox(height: 8),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => context.push('/auth/forgot-password'),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: ColorTokens.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark
                      ? ColorTokens.darkBorder
                      : ColorTokens.lightBorder,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark
                      ? ColorTokens.darkBorder
                      : ColorTokens.lightBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Google Sign-In
          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: isLoading,
          ),
          const SizedBox(height: 32),

          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.push('/auth/signup'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign Up',
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
                  child: formContent,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: formContent,
        ),
      ),
    );
  }
}
