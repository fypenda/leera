import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// An emoji on a soft, rounded square: the icon of a module, a format, a
/// card.
class EmojiBadge extends StatelessWidget {
  const EmojiBadge(
    this.emoji, {
    super.key,
    required this.background,
    this.size = 46,
  });

  final String emoji;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size >= 52 ? AppRadii.md : 14),
      ),
      child: ExcludeSemantics(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5, height: 1)),
      ),
    );
  }
}
