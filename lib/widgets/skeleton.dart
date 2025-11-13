import 'package:flutter/material.dart';

class SkeletonLine extends StatefulWidget {
  const SkeletonLine({super.key, this.height = 14, this.width, this.radius = 8});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.15, end: 0.35).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.dividerColor;
    return FadeTransition(
      opacity: _a,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: base.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.items = 5});
  final int items;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items, (i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SkeletonLine(height: 16),
          )),
    );
  }
}

