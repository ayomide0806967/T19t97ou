import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/toast_durations.dart';
import '../../../../core/navigation/app_nav.dart';
import '../../../../core/ui/app_toast.dart';
import '../../../../core/ui/initials.dart';
import '../../../../models/post.dart';
import '../../../../screens/post_activity_screen.dart';
import '../../../../screens/quote_screen.dart';
import '../../../../screens/thread_screen.dart';
import '../../../../theme/app_theme.dart';
// Removed card-style shell for timeline layout
import '../../../../widgets/hexagon_avatar.dart';
// import '../screens/post_detail_screen.dart'; // no longer used for replies
import '../../../../widgets/icons/x_comment_icon.dart';
import '../../../../widgets/icons/x_retweet_icon.dart';
import '../../../../widgets/icons/x_share_icon.dart';
import '../../../messages/application/message_thread_controller.dart';

part 'tweet_post_card_media.dart';
part 'tweet_post_card_metrics.dart';
part 'tweet_post_card_quote.dart';
part 'tweet_post_card_utils.dart';
part 'tweet_post_card_actions.dart';
part 'tweet_post_card_build.dart';

class TweetPostCard extends ConsumerStatefulWidget {
  const TweetPostCard({
    super.key,
    required this.post,
    required this.currentUserHandle,
    this.replyContext,
    this.onReply,
    this.backgroundColor,
    this.cornerAccentColor,
    this.showCornerAccent = true,
    this.onTap,
    this.showRepostBanner = false,
    this.showActions = true,
    this.fullWidthHeader = false,
    this.showTimeInHeader = true,
    this.toastDuration = ToastDurations.standard,
    this.showRepostToast = true,
  });

  final PostModel post;
  final String currentUserHandle;
  final String? replyContext;
  final ValueChanged<PostModel>? onReply;
  final Color? backgroundColor;
  final Color? cornerAccentColor;
  final bool showCornerAccent;
  final VoidCallback? onTap;
  final bool showRepostBanner;
  final bool showActions;
  // When true (e.g. on the thread/comments page), render the avatar + name
  // above the tweet so the body can run full width.
  final bool fullWidthHeader;
  // Controls whether the header meta row shows the time (e.g. "· 14h").
  final bool showTimeInHeader;
  final Duration toastDuration;
  final bool showRepostToast;

  @override
  ConsumerState<TweetPostCard> createState() => _TweetPostCardState();
}

abstract class _TweetPostCardStateBase extends ConsumerState<TweetPostCard> {
  static final math.Random _viewRandom = math.Random();

  late int _replies = widget.post.replies;
  late int _reposts = widget.post.reposts;
  late int _likes = widget.post.likes;
  late int _views = widget.post.views > 0
      ? widget.post.views
      : _generateViewCount(0);

  bool _liked = false;
  bool _bookmarked = false;
  OverlayEntry? _toastEntry;

  int _generateViewCount(int base) {
    final safeBase = base < 0 ? 0 : base;
    final randomAddition = (_viewRandom.nextInt(900) + 100) * 100;
    return safeBase + randomAddition;
  }

  String _withAtPrefix(String handle) {
    final trimmed = handle.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  @override
  void didUpdateWidget(covariant TweetPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.replies != widget.post.replies) {
      _replies = widget.post.replies;
      _reposts = widget.post.reposts;
      _likes = widget.post.likes;
      _views = widget.post.views;
    }
  }

  @override
  void dispose() {
    final entry = _toastEntry;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
    _toastEntry = null;
    super.dispose();
  }
}

class _TweetPostCardState extends _TweetPostCardStateBase
    with _TweetPostCardActions, _TweetPostCardBuild {}
