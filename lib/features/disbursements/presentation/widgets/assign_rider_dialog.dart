// lib/features/disbursements/presentation/widgets/assign_rider_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/disbursements/domain/repositories/disbursement_repository.dart';
import 'package:jireta_loan/features/disbursements/presentation/providers/disbursement_notifier.dart';

class AssignRiderDialog extends ConsumerStatefulWidget {
  final String disbursementId;

  const AssignRiderDialog({
    super.key,
    required this.disbursementId,
  });

  @override
  ConsumerState<AssignRiderDialog> createState() =>
      _AssignRiderDialogState();
}

class _AssignRiderDialogState extends ConsumerState<AssignRiderDialog> {
  String? _selectedRiderId;
  bool _isLoading = true;
  bool _isAssigning = false;
  List<RiderInfo> _riders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = ref.read(disbursementRepositoryProvider);
    final result = await repository.getAvailableRiders();

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (riders) {
        setState(() {
          _isLoading = false;
          _riders = riders;
        });
      },
    );
  }

  Future<void> _assignRider() async {
    if (_selectedRiderId == null) return;

    setState(() => _isAssigning = true);

    await ref.read(disbursementFeatureProvider.notifier).assignRider(
          disbursementId: widget.disbursementId,
          riderId: _selectedRiderId!,
        );

    if (mounted) {
      setState(() => _isAssigning = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.person_add_rounded,
            color: ColorTokens.accent,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Assign Rider'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: _buildContent(isDark),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAssigning ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRiderId != null && !_isAssigning
              ? _assignRider
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                ColorTokens.accent.withOpacity(0.5),
          ),
          child: _isAssigning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? ColorTokens.darkTextSecondary
                    : ColorTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRiders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_riders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 40,
              color: isDark
                  ? ColorTokens.darkDisabled
                  : ColorTokens.lightDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'No available riders',
              style: TextStyle(
                color: isDark
                    ? ColorTokens.darkTextSecondary
                    : ColorTokens.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All riders are currently busy. Try again later.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select a rider to assign to this disbursement:',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? ColorTokens.darkTextSecondary
                : ColorTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _riders.length,
            itemBuilder: (context, index) {
              final rider = _riders[index];
              final isSelected = _selectedRiderId == rider.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedRiderId = rider.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorTokens.accent.withOpacity(0.08)
                          : isDark
                              ? ColorTokens.darkSurface
                              : ColorTokens.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? ColorTokens.accent
                            : isDark
                                ? ColorTokens.darkBorder
                                : ColorTokens.lightBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: ColorTokens.roleRider
                              .withOpacity(0.12),
                          child: Text(
                            rider.name.isNotEmpty
                                ? rider.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.roleRider,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? ColorTokens.accent
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons
                                        .local_shipping_rounded,
                                    size: 12,
                                    color: isDark
                                        ? ColorTokens
                                            .darkTextSecondary
                                        : ColorTokens
                                            .lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${rider.activeDeliveries} active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? ColorTokens
                                              .darkTextSecondary
                                          : ColorTokens
                                              .lightTextSecondary,
                                    ),
                                  ),
                                  if (rider.phone != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.phone_rounded,
                                      size: 12,
                                      color: isDark
                                          ? ColorTokens
                                              .darkTextSecondary
                                          : ColorTokens
                                              .lightTextSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rider.phone!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? ColorTokens
                                                .darkTextSecondary
                                            : ColorTokens
                                                .lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: ColorTokens.accent,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
