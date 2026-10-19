import 'package:flutter/material.dart';

/// Lets a swipe from the left edge, to the right, go back with [onBack], as
/// on iOS, on a page that has nothing beneath it to swipe back to (a page
/// opened on its own, such as an English session or a deep link).
///
/// Where the page can be popped, the system's own back swipe already does
/// this, so nothing is added.
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({super.key, required this.onBack, required this.child});

  /// How wide the strip along the left edge is where the swipe starts.
  static const double edgeWidth = 24;

  /// How far, or how fast, the swipe must go to count.
  static const double minDistance = 80;
  static const double minVelocity = 400;

  final VoidCallback onBack;
  final Widget child;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  var _dragged = 0.0;

  @override
  Widget build(BuildContext context) {
    if (Navigator.maybeOf(context)?.canPop() ?? false) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: EdgeSwipeBack.edgeWidth,
          child: GestureDetector(
            key: const ValueKey('edge-swipe-back'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragged = 0,
            onHorizontalDragUpdate: (details) => _dragged += details.delta.dx,
            onHorizontalDragEnd: (details) {
              final fast =
                  (details.primaryVelocity ?? 0) > EdgeSwipeBack.minVelocity;
              if (_dragged > EdgeSwipeBack.minDistance || fast) {
                widget.onBack();
              }
            },
          ),
        ),
      ],
    );
  }
}
