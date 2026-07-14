// lib/shared/widgets/paginated_list.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';


class PaginatedList<T> extends StatelessWidget {
  final List<T> items;

  final bool isLoading;

  final bool hasMore;

  final VoidCallback onLoadMore;

  final Widget Function(T item) itemBuilder;

  final Widget Function()? emptyBuilder;

  final Widget Function(BuildContext, int)? separatorBuilder;

  final EdgeInsets padding;

  final ScrollController? scrollController;

  final double loadMoreTriggerDistance;

  const PaginatedList({
    super.key,
    required this.items,
    this.isLoading = false,
    this.hasMore = false,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyBuilder,
    this.separatorBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.scrollController,
    this.loadMoreTriggerDistance = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoading) {
      return emptyBuilder?.call() ?? const SizedBox.shrink();
    }

    final itemCount = items.length + (hasMore || isLoading ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: separatorBuilder ??
          (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= items.length - 3 &&
            hasMore &&
            !isLoading &&
            items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore();
          });
        }

        if (index == items.length) {
          return const _LoadMoreIndicator();
        }

        return itemBuilder(items[index]);
      },
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLight ? ColorTokens.accent : ColorTokens.accentLight,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more...',
              style: TextStyles.bodySmall(context).copyWith(
                color: isLight
                    ? ColorTokens.lightTextSecondary
                    : ColorTokens.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
