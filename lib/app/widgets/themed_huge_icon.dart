import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Drop-in replacement for `Icon(iconData)` that renders a HugeIcons glyph
/// while still inheriting size/color from the ambient [IconTheme] — so it
/// behaves correctly inside [NavigationRail], [Chip], [IconButton] etc.,
/// which set selected/unselected icon color via an inherited [IconTheme]
/// rather than an explicit `color:` argument.
class ThemedHugeIcon extends StatelessWidget {
  const ThemedHugeIcon(this.icon, {super.key, this.size, this.color});

  final List<List<dynamic>> icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      color:
          color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface,
      size: size ?? iconTheme.size ?? 24.0,
    );
  }
}
