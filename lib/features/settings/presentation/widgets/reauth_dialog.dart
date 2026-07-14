// lib/features/settings/presentation/widgets/reauth_dialog.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/validators.dart';

class ReauthDialog extends StatefulWidget {
  const ReauthDialog({super.key});

  static Future<ReauthResult?> show(BuildContext context) {
    return showDialog<ReauthResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReauthDialog(),
    );
  }

  @override
  State<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<ReauthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.shield_outlined, color: ColorTokens.lightWarning, size: 24),
          const SizedBox(width: 8),
          Text('Re-authentication Required',
              style: TextStyles.titleMedium(context)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action requires additional verification. Please enter your password and OTP to continue.',
                style: TextStyles.bodySmall(context),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                validator: Validators.password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _otpSent ? null : _sendOtp,
                  child: Text(_otpSent ? 'OTP Sent' : 'Send OTP'),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'OTP is required';
                    }
                    if (value.length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'One-Time Password',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _handleVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.accent,
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }

  void _sendOtp() {
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent to your registered device.'),
        backgroundColor: ColorTokens.lightSuccess,
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    await Future.delayed(const Duration(seconds: 1));

    final reAuthToken =
        'reauth_${DateTime.now().millisecondsSinceEpoch}_${_otpController.text}';

    if (mounted) {
      Navigator.of(context).pop(ReauthResult(
        reAuthToken: reAuthToken,
        password: _passwordController.text,
        otp: _otpController.text,
      ));
    }
  }
}

class ReauthResult {
  final String reAuthToken;
  final String password;
  final String otp;

  const ReauthResult({
    required this.reAuthToken,
    required this.password,
    required this.otp,
  });
}
