// lib/shared/widgets/skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor =
        isLight ? ColorTokens.lightSurface : ColorTokens.darkSurface;
    final highlightColor = isLight
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.04);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final bool isFullWidth;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: isFullWidth ? double.infinity : (width ?? 120),
      height: height,
      borderRadius: BorderRadius.all(Radius.circular(height / 2)),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      borderRadius: BorderRadius.all(Radius.circular(size / 2)),
    );
  }
}

class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 36, height: 36, borderRadius: BorderRadius.all(Radius.circular(10))),
            const SizedBox(height: 16),
            SkeletonLine(width: 80, height: 10),
            const SizedBox(height: 8),
            SkeletonLine(width: 140, height: 18),
            const SizedBox(height: 12),
            SkeletonLine(width: 90, height: 10),
          ],
        ),
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  final bool hasLeading;
  final int lineCount;

  const ListTileSkeleton({
    super.key,
    this.hasLeading = true,
    this.lineCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonCircle(size: 40),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < lineCount; i++) ...[
                  SkeletonLine(
                    width: i == 0 ? 180 : 120,
                    height: i == 0 ? 14 : 10,
                  ),
                  if (i < lineCount - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 60, height: 22, borderRadius: BorderRadius.all(Radius.circular(11))),
        ],
      ),
    );
  }
}

class TableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;

  const TableSkeleton({
    super.key,
    this.rows = 6,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              for (int c = 0; c < columns; c++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SkeletonLine(height: 10, isFullWidth: true),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (int r = 0; r < rows; r++) ...[
            Row(
              children: [
                for (int c = 0; c < columns; c++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: SkeletonLine(
                        height: 12,
                        isFullWidth: true,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
