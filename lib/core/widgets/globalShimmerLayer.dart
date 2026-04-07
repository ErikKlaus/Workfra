import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GlobalShimmerLayer extends StatelessWidget {
  final Widget child;

  const GlobalShimmerLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: Opacity(
            opacity: 0.05,
            child: Shimmer.fromColors(
              baseColor: Colors.white,
              highlightColor: const Color(0xFFEFF9FB),
              period: const Duration(milliseconds: 1800),
              child: Container(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
