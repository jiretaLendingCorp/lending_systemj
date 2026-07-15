// lib/features/auth/presentation/pages/login_page.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/validators.dart';
import 'package:jireta_loan/features/auth/presentation/providers/auth_notifier.dart';
import 'package:jireta_loan/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jireta_loan/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final AnimationController _shakeController;
  bool _isWeb = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }
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
    final isLoading = authState is AuthFeatureLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    ref.listen<AuthFeatureState>(authFeatureProvider, (prev, next) {
      if (next is AuthError) {
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(next.message)),
              ],
            ),
            backgroundColor: ColorTokens.lightError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedLogo(isDark: isDark)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.2, end: 0, duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 4),
          Text(
            'Sign in to your Jireta Loan account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),

          AuthTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            prefixIcon: Icon(
              LucideIcons.mail,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: () => _passwordFocus.requestFocus(),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 16),

          AuthTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              return null;
            },
            prefixIcon: Icon(
              LucideIcons.lock,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? LucideIcons.eye
                    : LucideIcons.eyeOff,
                size: 20,
                color: isDark
                    ? ColorTokens.darkTextSecondary
                    : ColorTokens.lightTextSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            onEditingComplete: _handleLogin,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideX(begin: 0.05, end: 0),
          const SizedBox(height: 8),

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
          ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final sineValue = sin(_shakeController.value * 3 * pi) * 8;
              return Transform.translate(
                offset: Offset(_shakeController.isAnimating ? sineValue : 0, 0),
                child: child,
              );
            },
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          key: ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logIn, size: 18),
                            SizedBox(width: 8),
                            Text('Sign In'),
                          ],
                        ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

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
          ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
          const SizedBox(height: 24),

          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: isLoading,
          )
              .animate()
              .fadeIn(delay: 800.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: theme.textTheme.bodyMedium?.copyWith(
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
          ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
        ],
      ),
    );

    if (_isWeb) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [ColorTokens.darkCanvas, ColorTokens.darkSurface]
                  : [ColorTokens.accent.withValues(alpha: 0.05), Colors.white],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 8,
                  shadowColor: ColorTokens.accent.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: formContent,
                  ),
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

class _AnimatedLogo extends StatelessWidget {
  final bool isDark;
  const _AnimatedLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.accent.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
