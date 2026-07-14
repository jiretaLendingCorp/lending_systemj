import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/core/utils/validators.dart';
import 'package:lendflow/features/users/presentation/providers/user_notifier.dart';
import 'package:lendflow/features/users/presentation/widgets/role_dropdown.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/shared/widgets/error_banner.dart';
import 'package:lendflow/shared/widgets/loading_overlay.dart';

/// Web: Create user form page with role assignment.
///
/// Allows admins to create new users by providing email, password,
/// full name, phone, branch, and role. Sensitive operations
/// require forced re-authentication.
class UserCreatePage extends ConsumerStatefulWidget {
  const UserCreatePage({super.key});

  @override
  ConsumerState<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends ConsumerState<UserCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _branchIdController = TextEditingController();
  UserRole _selectedRole = UserRole.borrower;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _branchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userFeatureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Create User', style: TextStyles.titleLarge(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New User',
                      style: TextStyles.headlineSmall(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new user account with role assignment.',
                      style: TextStyles.bodySmall(context),
                    ),
                    const SizedBox(height: 32),
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      validator: Validators.required,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      validator: Validators.password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Branch ID
                    TextFormField(
                      controller: _branchIdController,
                      decoration: const InputDecoration(
                        labelText: 'Branch ID (optional)',
                        prefixIcon: Icon(Icons.store_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role
                    Row(
                      children: [
                        Text('Role: ', style: TextStyles.labelLarge(context)),
                        const SizedBox(width: 12),
                        RoleDropdown(
                          currentRole: _selectedRole,
                          enabled: true,
                          onChanged: (role) {
                            setState(() {
                              _selectedRole = UserRole.fromString(role);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedRole == UserRole.admin)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorTokens.roleAdmin.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: ColorTokens.roleAdmin.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_outlined,
                                size: 18, color: ColorTokens.roleAdmin),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin role grants full system access. This action requires re-authentication.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ColorTokens.roleAdmin,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Create User'),
                      ),
                    ),
                    if (state is UserError) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(message: state.message),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (state is UsersLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(userFeatureProvider.notifier).createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          role: _selectedRole.toApiString(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          branchId: _branchIdController.text.trim().isEmpty
              ? null
              : _branchIdController.text.trim(),
        );
  }
}
