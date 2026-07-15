// lib/features/loans/presentation/pages/loan_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/loans/presentation/providers/loan_notifier.dart';
import 'package:jireta_loan/features/loans/presentation/widgets/loan_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoanListPage extends ConsumerStatefulWidget {
  const LoanListPage({super.key});

  @override
  ConsumerState<LoanListPage> createState() => _LoanListPageState();
}

class _LoanListPageState extends ConsumerState<LoanListPage> {
  final _searchController = TextEditingController();
  String? _activeFilter;
  bool _isSearching = false;

  static const _filterOptions = [
    (label: 'All', value: null),
    (label: 'Active', value: 'active'),
    (label: 'Pending', value: 'under_review'),
    (label: 'Approved', value: 'approved'),
    (label: 'Paid', value: 'paid'),
    (label: 'Defaulted', value: 'defaulted'),
    (label: 'Rejected', value: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanFeatureProvider.notifier).loadLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String? status) {
    setState(() => _activeFilter = status);
    ref.read(loanFeatureProvider.notifier).loadLoans(
          status: status,
          search: _searchController.text.trim().isNotEmpty
              ? _searchController.text.trim()
              : null,
        );
  }

  void _handleSearch(String query) {
    ref.read(loanFeatureProvider.notifier).loadLoans(
          status: _activeFilter,
          search: query.trim().isNotEmpty ? query.trim() : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<LoanFeatureState>(loanFeatureProvider, (prev, next) {
      if (next is LoanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _handleSearch('');
                }
              });
            },
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search loans...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _handleSearch('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _activeFilter == option.value;
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => _applyFilter(option.value),
                  backgroundColor: isDark
                      ? ColorTokens.darkSurface
                      : ColorTokens.lightSurface,
                  selectedColor: ColorTokens.accent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? ColorTokens.accent
                        : isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorTokens.accent
                        : isDark
                            ? ColorTokens.darkBorder
                            : ColorTokens.lightBorder,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          Expanded(
            child: _buildBody(loanState, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/lender/loan/apply'),
        tooltip: 'Apply for Loan',
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildBody(LoanFeatureState state, bool isDark) {
    if (state is LoansLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is LoanError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(loanFeatureProvider.notifier)
                  .loadLoans(status: _activeFilter),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is LoansLoaded) {
      if (state.loans.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.inbox,
                size: 64,
                color: isDark ? ColorTokens.darkDisabled : ColorTokens.lightDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No loans found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _activeFilter != null
                    ? 'Try a different filter or clear the current filter.'
                    : 'Apply for your first loan to get started.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

      return RefreshIndicator(
        onRefresh: () => ref
            .read(loanFeatureProvider.notifier)
            .loadLoans(status: _activeFilter),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200 &&
                state.hasMore) {
              ref.read(loanFeatureProvider.notifier).loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: state.loans.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.loans.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final loan = state.loans[index];
              return LoanCard(
                loan: loan,
                onTap: () {
                  context.push('/loans/${loan.id}');
                },
              );
            },
          ),
        ),
      );
    }

    if (state is LoanOperationSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(loanFeatureProvider.notifier).loadLoans(status: _activeFilter);
      });
    }

    return const SizedBox.shrink();
  }
}
