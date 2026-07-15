// lib/features/borrowers/presentation/pages/borrower_loan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:jireta_loan/features/borrowers/presentation/providers/borrower_notifier.dart';
import 'package:jireta_loan/features/borrowers/presentation/widgets/kyc_status_card.dart';
import 'package:jireta_loan/features/borrowers/presentation/widgets/loan_balance_card.dart';
import 'package:jireta_loan/features/borrowers/presentation/widgets/next_payment_card.dart';

class LenderLoanPage extends ConsumerStatefulWidget {
  const LenderLoanPage({super.key});

  @override
  ConsumerState<LenderLoanPage> createState() => _BorrowerLoanPageState();
}

class _BorrowerLoanPageState extends ConsumerState<LenderLoanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(borrowerFeatureProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borrowerState = ref.watch(borrowerFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () =>
                ref.read(borrowerFeatureProvider.notifier).loadProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(borrowerFeatureProvider.notifier).loadProfile(),
        child: CustomScrollView(
          slivers: [
            if (borrowerState is BorrowerLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (borrowerState is BorrowerError)
              SliverFillRemaining(
                child: _ErrorView(
                  message: borrowerState.message,
                  onRetry: () =>
                      ref.read(borrowerFeatureProvider.notifier).loadProfile(),
                ),
              )
            else if (borrowerState is BorrowerProfileLoaded) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: KycStatusCard(
                      kycStatus: borrowerState.profile.kycStatus),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: borrowerState.hasActiveLoan
                      ? LoanBalanceCard(
                          loan: borrowerState.currentLoan!,
                        )
                      : _NoActiveLoanCard(
                          canApply: borrowerState.profile.canApplyForLoan,
                          onApply: _navigateToLoanApplication,
                        ),
                ),
              ),

              if (borrowerState.hasActiveLoan &&
                  borrowerState.currentLoan!.dueAt != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: NextPaymentCard(
                      loan: borrowerState.currentLoan!,
                    ),
                  ),
                ),

              if (borrowerState.recentPayments.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Payments',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const _BorrowerPaymentsPageWrapper(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (!borrowerState.hasActiveLoan &&
                  borrowerState.profile.canApplyForLoan)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _navigateToLoanApplication,
                      icon: const Icon(LucideIcons.plusCircle),
                      label: const Text('Apply for New Loan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorTokens.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
            ]
            else
              const SliverFillRemaining(
                child: Center(child: Text('Welcome to Jireta Loan')),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToLoanApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _LoanApplicationWrapper(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _NoActiveLoanCard extends StatelessWidget {
  final bool canApply;
  final VoidCallback onApply;

  const _NoActiveLoanCard({required this.canApply, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(LucideIcons.wallet,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No Active Loan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canApply
                  ? 'You can apply for a new loan anytime.'
                  : 'Complete your KYC verification to apply for a loan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (canApply) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onApply,
                child: const Text('Apply Now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoanApplicationWrapper extends ConsumerWidget {
  const _LoanApplicationWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Loan Application')),
    );
  }
}

class _BorrowerPaymentsPageWrapper extends ConsumerWidget {
  const _BorrowerPaymentsPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Payments')),
    );
  }
}
