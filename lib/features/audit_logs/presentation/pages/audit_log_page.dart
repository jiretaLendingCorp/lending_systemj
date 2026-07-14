import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/features/audit_logs/domain/entities/audit_log.dart';
import 'package:lendflow/features/audit_logs/presentation/providers/audit_log_notifier.dart';
import 'package:lendflow/features/audit_logs/presentation/widgets/audit_log_row.dart';
import 'package:lendflow/features/audit_logs/presentation/widgets/log_detail_dialog.dart';
import 'package:lendflow/shared/widgets/empty_state.dart';
import 'package:lendflow/shared/widgets/error_banner.dart';
import 'package:lendflow/shared/widgets/loading_overlay.dart';
import 'package:lendflow/shared/widgets/search_bar_widget.dart';

/// Web: Audit log page with filters, search, and export.
///
/// Displays a filterable, searchable table of audit logs.
/// Audit logs are read-only (admin only).
class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _actionFilter;
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  void _loadLogs() {
    ref.read(auditLogFeatureProvider.notifier).loadLogs(
          action: _actionFilter,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogFeatureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Audit Logs',
                              style: TextStyles.headlineSmall(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Read-only record of all system actions. Admin access only.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportLogs,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Export CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Filter bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: 'Search by user ID or action...',
                        onChanged: (value) {
                          _searchQuery = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _ActionFilterDropdown(
                      currentFilter: _actionFilter,
                      onChanged: (value) {
                        setState(() => _actionFilter = value);
                        _loadLogs();
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Date Range',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Table header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? ColorTokens.lightSurface
                        : ColorTokens.darkSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 160, child: Text('Timestamp', style: TextStyles.labelMedium(context))),
                      Expanded(flex: 2, child: Text('User', style: TextStyles.labelMedium(context))),
                      Expanded(flex: 2, child: Text('Action', style: TextStyles.labelMedium(context))),
                      Expanded(flex: 2, child: Text('Entity', style: TextStyles.labelMedium(context))),
                      Expanded(flex: 1, child: Text('Diff', style: TextStyles.labelMedium(context))),
                      SizedBox(width: 120, child: Text('IP Address', style: TextStyles.labelMedium(context))),
                    ],
                  ),
                ),
              ),
              // Table body
              Expanded(
                child: switch (state) {
                  AuditLogsLoading() => const Center(child: CircularProgressIndicator()),
                  AuditLogError(:final message) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: ErrorBanner(message: message),
                    ),
                  AuditLogsLoaded(:final logs) => logs.isEmpty
                      ? const Center(
                          child: EmptyState(
                            icon: Icons.history_outlined,
                            title: 'No audit logs found',
                            subtitle: 'Try adjusting your filters or date range.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return AuditLogRow(
                              log: log,
                              onTap: () => LogDetailDialog.show(context, log),
                            );
                          },
                        ),
                  AuditLogExportSuccess(:final downloadUrl) => _buildExportView(downloadUrl),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
          if (state is AuditLogsLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildExportView(String downloadUrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(downloadUrl.isNotEmpty
              ? 'Export ready: $downloadUrl'
              : 'Export completed.'),
          backgroundColor: ColorTokens.lightSuccess,
        ),
      );
      _loadLogs();
    });
    return const SizedBox.shrink();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _loadLogs();
    }
  }

  void _exportLogs() {
    ref.read(auditLogFeatureProvider.notifier).exportLogs(
          action: _actionFilter,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Action filter dropdown for the audit log page.
class _ActionFilterDropdown extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onChanged;

  const _ActionFilterDropdown({
    required this.currentFilter,
    required this.onChanged,
  });

  static const _actions = [
    'user.create',
    'user.update',
    'user.deactivate',
    'user.reactivate',
    'user.reset_password',
    'user.force_logout',
    'user.role_change',
    'loan.create',
    'loan.approve',
    'loan.reject',
    'loan.disburse',
    'payment.record',
    'payment.verify',
    'settings.update',
    'settings.interest_rate',
    'settings.penalty_rate',
    'auth.login',
    'auth.logout',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightBorder
              : ColorTokens.darkBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: currentFilter,
          hint: Text('All Actions', style: theme.textTheme.bodySmall),
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Actions'),
            ),
            ..._actions.map((action) => DropdownMenuItem<String?>(
                  value: action,
                  child: Text(action),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
