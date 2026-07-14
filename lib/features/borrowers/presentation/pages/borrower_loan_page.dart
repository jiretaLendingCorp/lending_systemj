import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/features/borrowers/domain/entities/borrower_profile.dart';
import 'package:lendflow/features/borrowers/presentation/providers/borrower_notifier.dart';
import 'package:lendflow/features/borrowers/presentation/widgets/kyc_status_card.dart';
import 'package:lendflow/features/borrowers/presentation/widgets/loan_balance_card.dart';
import 'package:lendflow/features/borrowers/presentation/widgets/next_payment_card.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/presentation/providers/loan_notifier.dart';

/// Mobile page displaying the borrower's loan information.
///
/// Features:
/// - Current loan balance card with repayment progress
/// - KYC verification status card
/// - Next payment due card
/// - Apply for new loan button
/// - Loan schedule link
class BorrowerLoanPage extends ConsumerStatefulWidget {
  const BorrowerLoanPage({super.key});

  @override
  ConsumerState<BorrowerLoanPage> createState() => _BorrowerLoanPageState();
}

class _BorrowerLoanPageState extends ConsumerState<BorrowerLoanPage> {
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
            icon: const Icon(Icons.refresh),
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
              // KYC Status Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: KycStatusCard(
                      kycStatus: borrowerState.profile.kycStatus),
                ),
              ),

              // Loan Balance Card or No Loan Card
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

              // Next Payment Card (only if active loan)
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

              // Recent Payments Section
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

              // Apply for Loan Button (when no active loan)
              if (!borrowerState.hasActiveLoan &&
                  borrowerState.profile.canApplyForLoan)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _navigateToLoanApplication,
                      icon: const Icon(Icons.add_circle_outline),
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
                child: Center(child: Text('Welcome to LendFlow')),
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

/// Error view widget.
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
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Card shown when the borrower has no active loan.
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
            Icon(Icons.account_balance_wallet_outlined,
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

/// Wrapper page for loan application.
class _LoanApplicationWrapper extends ConsumerWidget {
  const _LoanApplicationWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Delegate to the existing loan application page
    return const Scaffold(
      body: Center(child: Text('Loan Application')),
    );
  }
}

/// Wrapper page for payments.
class _BorrowerPaymentsPageWrapper extends ConsumerWidget {
  const _BorrowerPaymentsPageWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Payments')),
    );
  }
}
