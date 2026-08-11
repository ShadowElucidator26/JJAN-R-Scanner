import 'package:flutter/material.dart';

enum SlideDirection { leftToRight, rightToLeft }

PageRouteBuilder slideTransition(Widget page, SlideDirection direction) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final beginOffset =
          direction == SlideDirection.leftToRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
      final endOffset = Offset.zero;

      final tween = Tween(begin: beginOffset, end: endOffset).chain(CurveTween(curve: Curves.easeInOut));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
