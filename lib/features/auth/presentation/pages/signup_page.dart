import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/validators.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lendflow/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:lendflow/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Signup page for new user registration.
///
/// Self-registration is limited to borrower and rider roles.
/// Admin and manager accounts are created via the admin panel.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  UserRole _selectedRole = UserRole.borrower;
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = kIsWeb;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authFeatureProvider.notifier).signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole.toApiString(),
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
      } else if (next is AuthOtpSent) {
        context.push('/auth/otp', extra: {'email': next.email});
      }
    });

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(
            Icons.person_add_rounded,
            size: 48,
            color: ColorTokens.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Join LendFlow to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Full Name
          AuthTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
            prefixIcon: Icon(
              Icons.person_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: () => _emailFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Email
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
            onEditingComplete: () => _phoneFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Phone
          AuthTextField(
            label: 'Phone Number',
            hint: '09XXXXXXXXX',
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: Validators.phone,
            prefixIcon: Icon(
              Icons.phone_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: () => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Role selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I am a',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RoleOption(
                      role: UserRole.borrower,
                      selectedRole: _selectedRole,
                      onTap: () => setState(() => _selectedRole = UserRole.borrower),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleOption(
                      role: UserRole.rider,
                      selectedRole: _selectedRole,
                      onTap: () => setState(() => _selectedRole = UserRole.rider),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Password
          AuthTextField(
            label: 'Password',
            hint: 'Create a strong password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
            prefixIcon: Icon(
              Icons.lock_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: () => _confirmPasswordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Confirm Password
          AuthTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                Validators.confirmPassword(value, _passwordController.text),
            prefixIcon: Icon(
              Icons.lock_outlined,
              size: 20,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
            onEditingComplete: _handleSignup,
          ),
          const SizedBox(height: 24),

          // Sign up button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSignup,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Account'),
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

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              TextButton(
                onPressed: isLoading ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign In',
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: formContent,
        ),
      ),
    );
  }
}

/// Selectable role option card for the signup form.
class _RoleOption extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleOption({
    required this.role,
    required this.selectedRole,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = role == selectedRole;
    final roleColor = role == UserRole.borrower
        ? ColorTokens.roleBorrower
        : ColorTokens.roleRider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? roleColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? roleColor
                : isDark
                    ? ColorTokens.darkBorder
                    : ColorTokens.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              role == UserRole.borrower
                  ? Icons.person_rounded
                  : Icons.two_wheeler_rounded,
              size: 28,
              color: isSelected ? roleColor : (isDark ? ColorTokens.darkDisabled : ColorTokens.lightDisabled),
            ),
            const SizedBox(height: 6),
            Text(
              role.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? roleColor
                    : isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
