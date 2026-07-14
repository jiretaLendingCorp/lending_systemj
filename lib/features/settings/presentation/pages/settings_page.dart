import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/features/settings/domain/entities/system_settings.dart';
import 'package:lendflow/features/settings/presentation/providers/settings_notifier.dart';
import 'package:lendflow/features/settings/presentation/widgets/reauth_dialog.dart';
import 'package:lendflow/features/settings/presentation/widgets/settings_section.dart';
import 'package:lendflow/shared/widgets/error_banner.dart';
import 'package:lendflow/shared/widgets/loading_overlay.dart';

/// Web: Settings page with all system configuration.
///
/// Organized into sections: Interest Rate, Penalty Settings,
/// SMS Templates, Notification Configuration, and System Flags.
/// Sensitive changes require forced re-authentication.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _interestRateController;
  late TextEditingController _penaltyRateController;
  late TextEditingController _penaltyThresholdController;
  late TextEditingController _smsTemplateController;

  @override
  void initState() {
    super.initState();
    _interestRateController = TextEditingController();
    _penaltyRateController = TextEditingController();
    _penaltyThresholdController = TextEditingController();
    _smsTemplateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsFeatureProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _interestRateController.dispose();
    _penaltyRateController.dispose();
    _penaltyThresholdController.dispose();
    _smsTemplateController.dispose();
    super.dispose();
  }

  void _updateControllers(SystemSettings settings) {
    _interestRateController.text = settings.interestRatePercent.toStringAsFixed(1);
    _penaltyRateController.text = settings.penaltyRatePercent.toStringAsFixed(1);
    _penaltyThresholdController.text = settings.penaltyThresholdDays.toString();
    _smsTemplateController.text = settings.smsTemplate;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsFeatureProvider);
    final theme = Theme.of(context);

    SystemSettings? currentSettings;
    if (state is SettingsLoaded) {
      currentSettings = state.settings;
      _updateControllers(currentSettings);
    } else if (state is SettingsUpdateSuccess) {
      currentSettings = state.settings;
      _updateControllers(currentSettings);
      // Show success snackbar once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: ColorTokens.lightSuccess,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('System Settings', style: TextStyles.headlineSmall(context)),
                    const SizedBox(height: 4),
                    Text(
                      'Configure system-wide parameters. Changes to interest and penalty rates require re-authentication.',
                      style: TextStyles.bodySmall(context),
                    ),
                    const SizedBox(height: 32),
                    if (state is SettingsError)
                      ErrorBanner(message: state.message),
                    if (state is SettingsError) const SizedBox(height: 16),

                    if (currentSettings != null) ...[
                      // Interest Rate Section
                      SettingsSection(
                        title: 'Interest Rate',
                        subtitle: 'Applied to all new loan applications',
                        icon: Icons.percent_outlined,
                        trailing: Tooltip(
                          message: 'Requires re-authentication',
                          child: Icon(Icons.shield_outlined,
                              size: 16, color: ColorTokens.lightWarning),
                        ),
                        children: [
                          SettingsRow(
                            label: 'Interest Rate',
                            description:
                                'Current rate applied per loan term (e.g., 20% means ₱20 interest per ₱100 borrowed)',
                            requiresReAuth: true,
                            control: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _interestRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      suffixText: '%',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _handleUpdateInterestRate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorTokens.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Penalty Settings Section
                      SettingsSection(
                        title: 'Penalty Settings',
                        subtitle: 'Configure overdue payment penalties',
                        icon: Icons.gavel_outlined,
                        trailing: Tooltip(
                          message: 'Requires re-authentication',
                          child: Icon(Icons.shield_outlined,
                              size: 16, color: ColorTokens.lightWarning),
                        ),
                        children: [
                          SettingsRow(
                            label: 'Penalty Rate',
                            description:
                                'Percentage of overdue amount charged as penalty',
                            requiresReAuth: true,
                            control: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _penaltyRateController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      suffixText: '%',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SettingsRow(
                            label: 'Penalty Threshold',
                            description:
                                'Number of days after due date before penalty applies',
                            requiresReAuth: true,
                            control: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _penaltyThresholdController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      suffixText: 'days',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _handleUpdatePenaltyRate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorTokens.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // SMS Template Section
                      SettingsSection(
                        title: 'SMS Template',
                        subtitle: 'Template for payment reminder SMS',
                        icon: Icons.sms_outlined,
                        children: [
                          TextFormField(
                            controller: _smsTemplateController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Hi {borrower_name}, ...',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available variables: {borrower_name}, {amount}, {due_date}, {loan_id}',
                            style: TextStyles.bodySmall(context),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _handleUpdateSmsTemplate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorTokens.accent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Template'),
                            ),
                          ),
                        ],
                      ),

                      // Notification Preferences Section
                      SettingsSection(
                        title: 'Notification Preferences',
                        subtitle: 'Configure how and when notifications are sent',
                        icon: Icons.notifications_outlined,
                        children: [
                          SettingsRow(
                            label: 'Email Notifications',
                            description: 'Send notifications via email',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.emailNotifications,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'email_notifications', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'SMS Notifications',
                            description: 'Send notifications via SMS',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.smsNotifications,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'sms_notifications', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Push Notifications',
                            description: 'Send push notifications to mobile devices',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.pushNotifications,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'push_notifications', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Overdue Alerts',
                            description: 'Alert admins/managers about overdue payments',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.overdueAlerts,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'overdue_alerts', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Payment Reminders',
                            description: 'Remind borrowers of upcoming payments',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.paymentReminders,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'payment_reminders', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'System Alerts',
                            description: 'Critical system alerts to administrators',
                            control: Switch(
                              value: currentSettings
                                  .notificationPreferences.systemAlerts,
                              onChanged: (value) =>
                                  _updateNotificationPref(
                                      'system_alerts', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                        ],
                      ),

                      // System Flags Section
                      SettingsSection(
                        title: 'System Flags',
                        subtitle: 'Feature toggles and maintenance controls',
                        icon: Icons.toggle_on_outlined,
                        children: [
                          SettingsRow(
                            label: 'Maintenance Mode',
                            description:
                                'Put the system in maintenance mode. Users cannot log in.',
                            requiresReAuth: true,
                            control: Switch(
                              value: currentSettings.systemFlags.maintenanceMode,
                              onChanged: (value) =>
                                  _updateSystemFlag('maintenance_mode', value,
                                      requiresReAuth: true,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Allow New Registrations',
                            description: 'Enable or disable new user registration',
                            control: Switch(
                              value: currentSettings
                                  .systemFlags.allowNewRegistrations,
                              onChanged: (value) =>
                                  _updateSystemFlag(
                                      'allow_new_registrations', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Allow Loan Applications',
                            description: 'Enable or disable new loan applications',
                            control: Switch(
                              value: currentSettings
                                  .systemFlags.allowLoanApplications,
                              onChanged: (value) =>
                                  _updateSystemFlag(
                                      'allow_loan_applications', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Auto-Approve Loans',
                            description:
                                'Automatically approve loans without manager review',
                            control: Switch(
                              value: currentSettings
                                  .systemFlags.autoApproveLoans,
                              onChanged: (value) =>
                                  _updateSystemFlag('auto_approve_loans', value,
                                      currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Enforce KYC Verification',
                            description:
                                'Require KYC documents before loan approval',
                            control: Switch(
                              value: currentSettings
                                  .systemFlags.enforceKycVerification,
                              onChanged: (value) => _updateSystemFlag(
                                  'enforce_kyc_verification', value,
                                  currentSettings: currentSettings!),
                            ),
                          ),
                          SettingsRow(
                            label: 'Disable Overdue Penalty',
                            description: 'Temporarily disable overdue penalties',
                            control: Switch(
                              value: currentSettings
                                  .systemFlags.disableOverduePenalty,
                              onChanged: (value) => _updateSystemFlag(
                                  'disable_overdue_penalty', value,
                                  currentSettings: currentSettings!),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (state is SettingsLoading && currentSettings == null)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
          if (state is SettingsLoading)
            const LoadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _handleUpdateInterestRate() async {
    final value = double.tryParse(_interestRateController.text);
    if (value == null || value <= 0 || value > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid interest rate (1-100%).'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }

    final reauthResult = await ReauthDialog.show(context);
    if (reauthResult == null) return;

    ref.read(settingsFeatureProvider.notifier).updateInterestRate(
          interestRate: value / 100,
          reAuthToken: reauthResult.reAuthToken,
        );
  }

  Future<void> _handleUpdatePenaltyRate() async {
    final rate = double.tryParse(_penaltyRateController.text);
    final threshold = int.tryParse(_penaltyThresholdController.text);
    if (rate == null || rate <= 0 || rate > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid penalty rate (1-100%).'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }
    if (threshold == null || threshold < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid threshold (0+ days).'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }

    final reauthResult = await ReauthDialog.show(context);
    if (reauthResult == null) return;

    ref.read(settingsFeatureProvider.notifier).updatePenaltyRate(
          penaltyRate: rate / 100,
          penaltyThresholdDays: threshold,
          reAuthToken: reauthResult.reAuthToken,
        );
  }

  void _handleUpdateSmsTemplate() {
    final template = _smsTemplateController.text.trim();
    if (template.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS template cannot be empty.'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }
    ref.read(settingsFeatureProvider.notifier).updateSmsTemplate(
          smsTemplate: template,
        );
  }

  void _updateNotificationPref(
    String key,
    bool value, {
    required SystemSettings currentSettings,
  }) {
    final prefs = <String, dynamic>{
      'email_notifications': currentSettings.notificationPreferences.emailNotifications,
      'sms_notifications': currentSettings.notificationPreferences.smsNotifications,
      'push_notifications': currentSettings.notificationPreferences.pushNotifications,
      'overdue_alerts': currentSettings.notificationPreferences.overdueAlerts,
      'payment_reminders': currentSettings.notificationPreferences.paymentReminders,
      'system_alerts': currentSettings.notificationPreferences.systemAlerts,
    };
    prefs[key] = value;

    ref.read(settingsFeatureProvider.notifier).updateNotificationPreferences(
          preferences: prefs,
        );
  }

  Future<void> _updateSystemFlag(
    String key,
    bool value, {
    bool requiresReAuth = false,
    required SystemSettings currentSettings,
  }) async {
    String? reAuthToken;
    if (requiresReAuth) {
      final reauthResult = await ReauthDialog.show(context);
      if (reauthResult == null) return;
      reAuthToken = reauthResult.reAuthToken;
    }

    final flags = <String, dynamic>{
      'maintenance_mode': currentSettings.systemFlags.maintenanceMode,
      'allow_new_registrations': currentSettings.systemFlags.allowNewRegistrations,
      'allow_loan_applications': currentSettings.systemFlags.allowLoanApplications,
      'auto_approve_loans': currentSettings.systemFlags.autoApproveLoans,
      'enforce_kyc_verification': currentSettings.systemFlags.enforceKycVerification,
      'disable_overdue_penalty': currentSettings.systemFlags.disableOverduePenalty,
    };
    flags[key] = value;

    ref.read(settingsFeatureProvider.notifier).updateSystemFlags(
          flags: flags,
          reAuthToken: reAuthToken,
        );
  }
}
