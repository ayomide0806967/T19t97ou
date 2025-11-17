import 'package:flutter/material.dart';

/// Vertical step rail with numbered dots and optional titles.
///
/// Mirrors the visual used in iOS messages demo, extracted for reuse.
class StepRailVertical extends StatelessWidget {
  const StepRailVertical({
    super.key,
    required this.steps,
    required this.activeIndex,
    this.titles,
    this.onStepTap,
  });

  /// Dot labels (e.g., ['1','2','3','4']).
  final List<String> steps;

  /// Optional titles for each step placed to the right of the dots.
  final List<String>? titles;

  /// Currently active step index.
  final int activeIndex;

  /// Tap handler for steps.
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasTitles = titles != null && titles!.length == steps.length;
    final Color connectorColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);
    const double dotSize = 24;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StepDot(active: i == activeIndex, label: steps[i], size: dotSize),
                  if (hasTitles) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        titles![i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: i == activeIndex ? FontWeight.w700 : FontWeight.w600,
                          color: i == activeIndex
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (i < steps.length - 1)
            Row(
              children: [
                const SizedBox(width: dotSize / 2),
                Container(width: 1, height: 28, color: connectorColor),
                if (hasTitles) const SizedBox(width: 10),
                if (hasTitles) const Expanded(child: SizedBox()),
              ],
            ),
        ],
      ],
    );
  }
}

/// Horizontal step rail with numbered dots and connectors.
/// Intended to sit above the content so the active step's
/// form appears directly under the corresponding number.
class StepRailHorizontal extends StatelessWidget {
  const StepRailHorizontal({
    super.key,
    required this.steps,
    required this.activeIndex,
    this.onStepTap,
    this.dotSize = 24,
    this.gap = 28,
  });

  final List<String> steps;
  final int activeIndex;
  final ValueChanged<int>? onStepTap;
  final double dotSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color connectorColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          InkWell(
            onTap: onStepTap == null ? null : () => onStepTap!(i),
            borderRadius: BorderRadius.circular(dotSize / 2),
            child: _StepDot(active: i == activeIndex, label: steps[i], size: dotSize),
          ),
          if (i < steps.length - 1)
            Container(
              width: gap,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: connectorColor,
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label, this.size = 24});
  final bool active;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color border = theme.colorScheme.onSurface;
    final Color fill = active ? Colors.black : Colors.white;
    final Color text = active ? Colors.white : Colors.black;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: size == 24 ? 12 : 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
