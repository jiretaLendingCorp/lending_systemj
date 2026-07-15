// lib/features/auth/presentation/widgets/auth_text_field.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final bool autofocus;
  final String? initialValue;
  final int maxLength;
  final TextCapitalization textCapitalization;

  const AuthTextField({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
    this.initialValue,
    this.maxLength = 0,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = widget.focusNode?.hasFocus ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _hasFocus
                  ? ColorTokens.accent
                  : isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          textInputAction: widget.textInputAction,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          initialValue: widget.initialValue,
          maxLength: widget.maxLength > 0 ? widget.maxLength : null,
          textCapitalization: widget.textCapitalization,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
