import 'package:flutter/material.dart';

/// A simple row that renders its children with equal width and a unified height.
/// Each child is wrapped in Expanded and a SizedBox(height: [height]).
class EqualWidthButtonsRow extends StatelessWidget {
  const EqualWidthButtonsRow({
    super.key,
    required this.children,
    this.gap = 12,
    this.height = 44,
  });

  final List<Widget> children;
  final double gap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final List<Widget> row = [];
    for (int i = 0; i < children.length; i++) {
      row.add(
        Expanded(
          child: SizedBox(height: height, child: children[i]),
        ),
      );
      if (i != children.length - 1) row.add(SizedBox(width: gap));
    }
    return Row(children: row);
  }
}

