import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';


/// Generic paginated list with load-more indicator.
///
/// Renders a [ListView.builder] that appends a "load more" trigger
/// at the bottom of the visible list. When the user scrolls near the
/// end, [onLoadMore] is called. A loading indicator is shown while
/// more items are being fetched.
///
/// ```dart
/// PaginatedList<User>(
///   items: users,
///   isLoading: loadingMore,
///   hasMore: hasMorePages,
///   onLoadMore: () => notifier.loadMore(),
///   itemBuilder: (user) => UserTile(user: user),
///   emptyBuilder: () => EmptyState(icon: ..., title: ...),
/// )
/// ```
class PaginatedList<T> extends StatelessWidget {
  /// Current page of items to display.
  final List<T> items;

  /// Whether a load-more request is currently in flight.
  final bool isLoading;

  /// Whether more pages exist on the server.
  final bool hasMore;

  /// Called when the user scrolls to the bottom and more data is needed.
  final VoidCallback onLoadMore;

  /// Builder for each item in the list.
  final Widget Function(T item) itemBuilder;

  /// Builder for the empty state when [items] is empty.
  final Widget Function()? emptyBuilder;

  /// Optional separator between items.
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// Padding around the list.
  final EdgeInsets padding;

  /// Scroll controller for external access.
  final ScrollController? scrollController;

  /// The distance from the bottom (in pixels) at which [onLoadMore]
  /// is triggered. Defaults to 200.
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
        // Load-more trigger: when near the end, request more data.
        if (index >= items.length - 3 &&
            hasMore &&
            !isLoading &&
            items.isNotEmpty) {
          // Schedule outside build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore();
          });
        }

        // Last item: loading indicator
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
