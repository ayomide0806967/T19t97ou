import 'package:flutter/widgets.dart';

class QuickControlGrid extends StatelessWidget {
  const QuickControlGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxColumns = 3,
    this.columnGap = 14,
    this.rowGap = 10,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int maxColumns;
  final double columnGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    final columns = itemCount < maxColumns ? itemCount : maxColumns;
    final rows = (itemCount / columns).ceil();
    final List<Widget> gridRows = [];

    for (var row = 0; row < rows; row++) {
      final int startIndex = row * columns;
      if (startIndex >= itemCount) break;

      final List<Widget> cells = [];
      for (var column = 0; column < columns; column++) {
        final index = startIndex + column;
        final hasItem = index < itemCount;
        cells.add(
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: column == columns - 1 ? 0 : columnGap),
              child: hasItem ? itemBuilder(context, index) : const SizedBox.shrink(),
            ),
          ),
        );
      }

      gridRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : rowGap),
          child: Row(children: cells),
        ),
      );
    }

    return Column(children: gridRows);
  }
}

