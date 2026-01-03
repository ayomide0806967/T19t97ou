part of '../ios_messages_screen.dart';

class _ThreadNode {
  _ThreadNode({required this.comment, List<_ThreadNode>? children})
    : children = children != null
          ? List<_ThreadNode>.from(children)
          : <_ThreadNode>[];
  final _ThreadComment comment;
  final List<_ThreadNode> children;
}

class _ThreadCommentsView extends StatelessWidget {
  const _ThreadCommentsView({
    required this.nodes,
    required this.currentUserHandle,
    this.onReply,
    this.onMore,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });
  final List<_ThreadNode> nodes;
  final String currentUserHandle;
  final ValueChanged<_ThreadNode>? onReply;
  final ValueChanged<_ThreadNode>? onMore;
  final bool selectionMode;
  final Set<_ThreadNode> selected;
  final void Function(_ThreadNode node) onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < nodes.length; i++)
          _ThreadNodeTile(
            node: nodes[i],
            depth: 0,
            isLast: i == nodes.length - 1,
            currentUserHandle: currentUserHandle,
            onReply: onReply,
            onMore: onMore,
            selectionMode: selectionMode,
            selected: selected,
            onToggleSelect: () => onToggleSelect(nodes[i]),
          ),
      ],
    );
  }
}

class _ThreadNodeTile extends StatelessWidget {
  const _ThreadNodeTile({
    required this.node,
    required this.depth,
    required this.isLast,
    required this.currentUserHandle,
    this.onReply,
    this.onMore,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
  });
  final _ThreadNode node;
  final int depth;
  final bool isLast;
  final String currentUserHandle;
  final ValueChanged<_ThreadNode>? onReply;
  final ValueChanged<_ThreadNode>? onMore;
  final bool selectionMode;
  final Set<_ThreadNode> selected;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final indent = 18.0 * depth;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (depth > 0) ...[
                Container(
                  width: 10,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.only(top: 8, bottom: isLast ? 18 : 4),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: _CommentTile(
                  comment: node.comment,
                  isDark: isDark,
                  currentUserHandle: currentUserHandle,
                  onSwipeReply: selectionMode
                      ? null
                      : () => onReply?.call(node),
                  onMore: selectionMode ? null : () => onMore?.call(node),
                  selected: selected.contains(node),
                  onLongPress: onToggleSelect,
                  onTap: selectionMode ? onToggleSelect : null,
                ),
              ),
            ],
          ),
          if (node.children.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < node.children.length; i++)
                  _ThreadNodeTile(
                    node: node.children[i],
                    depth: depth + 1,
                    isLast: i == node.children.length - 1,
                    currentUserHandle: currentUserHandle,
                    onReply: onReply,
                    onMore: onMore,
                    selectionMode: selectionMode,
                    selected: selected,
                    onToggleSelect: onToggleSelect,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ThreadComment {
  const _ThreadComment({
    required this.author,
    required this.timeAgo,
    required this.body,
    this.likes = 0,
    this.quotedFrom,
    this.quotedBody,
  });
  final String author;
  final String timeAgo;
  final String body;
  final int likes;
  final String? quotedFrom;
  final String? quotedBody;
}
