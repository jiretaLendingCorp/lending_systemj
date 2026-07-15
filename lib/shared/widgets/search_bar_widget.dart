// lib/shared/widgets/search_bar_widget.dart
import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;

  final ValueChanged<String> onChanged;

  final Duration debounceDuration;

  final TextEditingController? controller;

  final bool enabled;

  final VoidCallback? onCleared;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search...',
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
    this.enabled = true,
    this.onCleared,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(_controller.text);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      style: TextStyles.bodyMedium(context),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isLight ? ColorTokens.lightDisabled : ColorTokens.darkDisabled,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          LucideIcons.search,
          size: 20,
          color: isLight
              ? ColorTokens.lightTextSecondary
              : ColorTokens.darkTextSecondary,
        ),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: isLight
                      ? ColorTokens.lightTextSecondary
                      : ColorTokens.darkTextSecondary,
                ),
                onPressed: _clear,
                splashRadius: 16,
              )
            : null,
        filled: true,
        fillColor: isLight ? ColorTokens.lightSurface : ColorTokens.darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorTokens.accent, width: 2),
        ),
      ),
    );
  }
}
