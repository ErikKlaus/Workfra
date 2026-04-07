import 'package:flutter/material.dart';

Route<T> buildFadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 250),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
