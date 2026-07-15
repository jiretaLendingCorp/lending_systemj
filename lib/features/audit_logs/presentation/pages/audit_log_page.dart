// lib/features/audit_logs/presentation/pages/audit_log_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:jireta_loan/features/audit_logs/presentation/providers/audit_log_notifier.dart';
import 'package:jireta_loan/features/audit_logs/presentation/widgets/audit_log_row.dart';
import 'package:jireta_loan/features/audit_logs/presentation/widgets/log_detail_dialog.dart';
import 'package:jireta_loan/shared/widgets/empty_state.dart';
import 'package:jireta_loan/shared/widgets/error_banner.dart';
import 'package:jireta_loan/shared/widgets/loading_overlay.dart';
import 'package:jireta_loan/shared/widgets/search_bar_widget.dart';

class AuditLogPage extends ConsumerStatefulWidget {
  const AuditLogPage({super.key});

  @override
  ConsumerState<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends ConsumerState<AuditLogPage> {
  String? _actionFilter;
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
                            'Read-only record of all system actions. HeadManager access only.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportLogs,
                      icon: const Icon(LucideIcons.download, size: 18),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: 'Search by user ID or action...',
                        onChanged: (value) {
                          ref
                              .read(auditLogFeatureProvider.notifier)
                              .loadLogs(userId: value.isEmpty ? null : value);
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
                      icon: const Icon(LucideIcons.calendarRange, size: 18),
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
                            icon: LucideIcons.history,
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
