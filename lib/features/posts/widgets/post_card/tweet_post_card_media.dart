part of 'tweet_post_card.dart';

/// Simple demo media carousel that allows horizontal swiping between
/// multiple images, inspired by Instagram's multi-photo posts.
class _TweetMediaCarousel extends StatefulWidget {
  @override
  State<_TweetMediaCarousel> createState() => _TweetMediaCarouselState();
}

class _TweetMediaCarouselState extends State<_TweetMediaCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color border = theme.dividerColor.withValues(
      alpha: isDark ? 0.4 : 0.24,
    );

    const int itemCount = 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _controller,
            itemCount: itemCount,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/in_logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            itemCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _index == i ? 8 : 6,
              height: _index == i ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _index == i
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PostMediaGrid extends StatefulWidget {
  const _PostMediaGrid({required this.paths});

  final List<String> paths;

  @override
  State<_PostMediaGrid> createState() => _PostMediaGridState();
}

class _PostMediaGridState extends State<_PostMediaGrid>
    with AutomaticKeepAliveClientMixin<_PostMediaGrid> {
  PageController? _controller;

  @override
  bool get wantKeepAlive => true;

  void _syncController(int itemCount) {
    if (itemCount <= 1) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    _controller ??= PageController(viewportFraction: 0.75);
  }

  @override
  void didUpdateWidget(covariant _PostMediaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextCount =
        widget.paths.where((p) => p.trim().isNotEmpty).length;
    _syncController(nextCount);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = Border.all(
      color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.2),
      width: 0.8,
    );

    final cleaned = widget.paths.where((p) => p.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();
    _syncController(cleaned.length);

    Widget tile(String path, int index) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder<void>(
              barrierColor: Colors.black,
              opaque: true,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, __, ___) => _FullScreenMediaViewer(
                paths: cleaned,
                initialIndex: index,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(border: border),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final int? cacheWidth = constraints.maxWidth.isFinite
                    ? (constraints.maxWidth * dpr).round()
                    : null;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.04,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _PostMediaImage(
                        path: path,
                        cacheWidth: cacheWidth,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }

    if (cleaned.length == 1) {
      return AspectRatio(
        aspectRatio: 3 / 4,
        child: tile(cleaned.first, 0),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 230,
      child: PageView.builder(
        itemCount: cleaned.length,
        controller: _controller,
        padEnds: false,
        itemBuilder: (context, index) {
          final path = cleaned[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == cleaned.length - 1 ? 0 : 8,
            ),
            child: tile(path, index),
          );
        },
      ),
    );
  }
}

class _FullScreenMediaViewer extends StatelessWidget {
  const _FullScreenMediaViewer({
    required this.paths,
    required this.initialIndex,
  });

  final List<String> paths;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                return Center(
                  child: InteractiveViewer(
                    child: _PostMediaImage(path: path, fit: BoxFit.contain),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMediaImage extends StatelessWidget {
  const _PostMediaImage({
    required this.path,
    required this.fit,
    this.cacheWidth,
  });

  final String path;
  final BoxFit fit;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = path.trim();

    Widget placeholder() => Container(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        );

    if (trimmed.isEmpty) return placeholder();

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        fit: fit,
        placeholder: (_, __) => Container(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        ),
        errorWidget: (_, __, ___) => placeholder(),
      );
    }

    final File file;
    if (uri != null && uri.scheme == 'file') {
      file = File.fromUri(uri);
    } else {
      file = File(trimmed);
    }

    if (!file.existsSync()) return placeholder();

    return Image.file(
      file,
      key: ValueKey<String>(trimmed),
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheWidth != null && cacheWidth! > 0 ? cacheWidth : null,
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}
