import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  final Widget child;

  const ShimmerSkeleton({super.key, required this.child});

  Color _resolveBaseColor(ColorScheme colorScheme, bool isDark) {
    if (isDark) {
      return const Color(0xFF2E2E2E);
    }

    return const Color(0xFFA6A6A6);
  }

  Color _resolveHighlightColor(ColorScheme colorScheme, bool isDark) {
    if (isDark) {
      return const Color(0xFF474747);
    }

    return const Color(0xFFC5C5C5);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: _resolveBaseColor(colorScheme, isDark),
      highlightColor: _resolveHighlightColor(colorScheme, isDark),
      child: child,
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius,
      ),
    );
  }
}
