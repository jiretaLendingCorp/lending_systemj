import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';
import 'package:lendflow/features/riders/presentation/providers/rider_notifier.dart';
import 'package:lendflow/features/riders/presentation/widgets/gps_checkin_button.dart';

/// Mobile page displaying a Google Maps view of the rider's task locations.
///
/// Features:
/// - Map markers for each task location, color-coded by type
/// - GPS check-in button for the selected task
/// - Bottom sheet with task details when a marker is tapped
/// - Current location tracking
class RiderMapPage extends ConsumerStatefulWidget {
  const RiderMapPage({super.key});

  @override
  ConsumerState<RiderMapPage> createState() => _RiderMapPageState();
}

class _RiderMapPageState extends ConsumerState<RiderMapPage> {
  GoogleMapController? _mapController;
  RiderTask? _selectedTask;
  LatLng? _currentLocation;

  // Default to Manila, Philippines
  static const _defaultPosition = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderFeatureProvider.notifier).loadTodayTasks();
    });
  }

  Set<Marker> _buildMarkers(List<RiderTask> tasks) {
    return tasks.where((t) => t.hasGpsCoordinates).map((task) {
      final position = LatLng(task.gpsLatitude, task.gpsLongitude);
      final markerColor = task.isDisbursement
          ? BitmapDescriptor.hueAzure
          : BitmapDescriptor.hueOrange;

      return Marker(
        markerId: MarkerId(task.id),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
        infoWindow: InfoWindow(
          title: task.borrowerName,
          snippet:
              '${task.type.label}: ${_formatAmount(task.amount)}',
        ),
        onTap: () {
          setState(() => _selectedTask = task);
          _showTaskBottomSheet(task);
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riderState = ref.watch(riderFeatureProvider);
    final tasks = riderState is RiderTasksLoaded ? riderState.tasks : <RiderTask>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Map'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultPosition,
              zoom: 12,
            ),
            markers: _buildMarkers(tasks),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMarkers(tasks);
            },
            onCameraMove: (_) {},
          ),

          // Legend
          Positioned(
            top: 16,
            left: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legend',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _legendItem(Colors.blue, 'Disbursement'),
                    const SizedBox(height: 4),
                    _legendItem(Colors.orange, 'Collection'),
                    if (_currentLocation != null) ...[
                      const SizedBox(height: 4),
                      _legendItem(Colors.blue.withOpacity(0.5), 'Your Location'),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Task count badge
          if (tasks.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // GPS Check-in button (bottom)
          if (_selectedTask != null && _selectedTask!.status.isActive)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: GpsCheckinButton(
                task: _selectedTask!,
                onCheckin: (latitude, longitude) {
                  ref.read(riderFeatureProvider.notifier).gpsCheckin(
                        taskId: _selectedTask!.id,
                        latitude: latitude,
                        longitude: longitude,
                      );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _showTaskBottomSheet(RiderTask task) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    task.isDisbursement
                        ? Icons.outbox_outlined
                        : Icons.inbox_outlined,
                    color: task.isDisbursement
                        ? ColorTokens.accent
                        : ColorTokens.secondaryAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.borrowerName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor(task.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(Icons.location_on_outlined, task.borrowerAddress),
              const SizedBox(height: 8),
              _infoRow(
                Icons.payments_outlined,
                '${task.type.label}: ${_formatAmount(task.amount)}',
              ),
              const SizedBox(height: 8),
              _infoRow(
                Icons.description_outlined,
                'Loan: ${task.loanId.substring(0, 8)}...',
              ),
              const SizedBox(height: 20),
              if (task.status.isActive)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _animateToTask(task);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorTokens.lightTextSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Color _statusColor(RiderTaskStatus status) {
    return switch (status) {
      RiderTaskStatus.pending => ColorTokens.lightWarning,
      RiderTaskStatus.assigned => ColorTokens.lightInfo,
      RiderTaskStatus.inTransit => ColorTokens.accent,
      RiderTaskStatus.completed => ColorTokens.lightSuccess,
      RiderTaskStatus.failed => ColorTokens.lightError,
    };
  }

  void _animateToTask(RiderTask task) {
    if (task.hasGpsCoordinates) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(task.gpsLatitude, task.gpsLongitude),
          16,
        ),
      );
    }
  }

  void _fitMarkers(List<RiderTask> tasks) {
    final validTasks = tasks.where((t) => t.hasGpsCoordinates).toList();
    if (validTasks.isEmpty) return;

    if (validTasks.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(validTasks.first.gpsLatitude, validTasks.first.gpsLongitude),
          15,
        ),
      );
      return;
    }

    final bounds = _calculateBounds(validTasks);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds(List<RiderTask> tasks) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final task in tasks) {
      if (task.gpsLatitude < minLat) minLat = task.gpsLatitude;
      if (task.gpsLatitude > maxLat) maxLat = task.gpsLatitude;
      if (task.gpsLongitude < minLng) minLng = task.gpsLongitude;
      if (task.gpsLongitude > maxLng) maxLng = task.gpsLongitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String _formatAmount(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }
}
