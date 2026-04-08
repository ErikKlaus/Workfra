import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GlobalShimmerLayer extends StatelessWidget {
  final Widget child;

  const GlobalShimmerLayer({super.key, required this.child});

  Color _resolveBaseColor(bool isDark) {
    return isDark ? const Color(0xFF2F2F2F) : const Color(0xFFA3A3A3);
  }

  Color _resolveHighlightColor(bool isDark) {
    return isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC2C2C2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = _resolveBaseColor(isDark);
    final highlightColor = _resolveHighlightColor(isDark);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: Opacity(
            opacity: isDark ? 0.14 : 0.1,
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              period: const Duration(milliseconds: 1800),
              child: Container(color: baseColor),
            ),
          ),
        ),
      ],
    );
  }
}
