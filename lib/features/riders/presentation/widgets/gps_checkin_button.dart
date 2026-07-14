// lib/features/riders/presentation/widgets/gps_checkin_button.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';

class GpsCheckinButton extends StatefulWidget {
  final RiderTask task;
  final Future<void> Function(double latitude, double longitude) onCheckin;

  const GpsCheckinButton({
    super.key,
    required this.task,
    required this.onCheckin,
  });

  @override
  State<GpsCheckinButton> createState() => _GpsCheckinButtonState();
}

class _GpsCheckinButtonState extends State<GpsCheckinButton> {
  GpsCheckinStatus _status = GpsCheckinStatus.idle;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _StatusDot(status: _status),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.lightError,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_status == GpsCheckinStatus.idle)
                        Text(
                          '${widget.task.lenderName} – ${widget.task.type.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: _status == GpsCheckinStatus.success
                  ? _buildSuccessButton(theme)
                  : _status == GpsCheckinStatus.loading
                      ? _buildLoadingButton(theme)
                      : _buildCheckinButton(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _handleCheckin,
      icon: const Icon(Icons.my_location),
      label: const Text('GPS Check-In'),
      style: FilledButton.styleFrom(
        backgroundColor: ColorTokens.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: null,
      icon: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      label: const Text('Checking in...'),
      style: FilledButton.styleFrom(
        backgroundColor: ColorTokens.accent.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSuccessButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: null,
      icon: const Icon(Icons.check_circle, size: 20),
      label: const Text('Checked In'),
      style: FilledButton.styleFrom(
        backgroundColor: ColorTokens.lightSuccess,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleCheckin() async {
    setState(() {
      _status = GpsCheckinStatus.loading;
      _errorMessage = null;
    });

    try {
      await widget.onCheckin(
        widget.task.gpsLatitude,
        widget.task.gpsLongitude,
      );

      if (mounted) {
        setState(() => _status = GpsCheckinStatus.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = GpsCheckinStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String get _statusTitle => switch (_status) {
        GpsCheckinStatus.idle => 'Ready to Check In',
        GpsCheckinStatus.loading => 'Verifying Location...',
        GpsCheckinStatus.success => 'Check-In Successful',
        GpsCheckinStatus.error => 'Check-In Failed',
      };
}

enum GpsCheckinStatus {
  idle,
  loading,
  success,
  error;
}

class _StatusDot extends StatelessWidget {
  final GpsCheckinStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GpsCheckinStatus.idle => ColorTokens.lightWarning,
      GpsCheckinStatus.loading => ColorTokens.lightInfo,
      GpsCheckinStatus.success => ColorTokens.lightSuccess,
      GpsCheckinStatus.error => ColorTokens.lightError,
    };

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
