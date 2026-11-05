import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Motion tokens. Strong ease-out for anything entering or responding to the
/// user (starts fast, so the app feels like it heard you); never ease-in.
abstract final class Motion {
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
  static const press = Duration(milliseconds: 160);
  static const page = Duration(milliseconds: 260);
  static const pageBack = Duration(milliseconds: 180);

  /// Explanatory motion (drawing the water curve) may run longer than UI motion.
  static const explain = Duration(milliseconds: 700);

  /// Reduced motion: honour the platform setting by skipping movement.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Scales its child to 0.97 while pressed: instant feedback for anything tappable.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !Motion.reduced(context) ? 0.97 : 1,
      duration: Motion.press,
      curve: Motion.easeOut,
      child: widget.child,
    ),
  );
}

/// Page that fades in from 98% scale; leaving is faster than arriving.
CustomTransitionPage<void> fadeScalePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.page,
      reverseTransitionDuration: Motion.pageBack,
      transitionsBuilder: (context, animation, secondary, child) {
        if (Motion.reduced(context)) {
          return FadeTransition(opacity: animation, child: child);
        }
        final a = CurvedAnimation(
          parent: animation,
          curve: Motion.easeOut,
          reverseCurve: Motion.easeOut.flipped,
        );
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(a),
            child: child,
          ),
        );
      },
    );
