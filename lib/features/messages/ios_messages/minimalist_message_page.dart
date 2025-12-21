part of '../ios_messages_screen.dart';

/// Minimalist iOS-style messages inbox page.
class IosMinimalistMessagePage extends StatefulWidget {
  const IosMinimalistMessagePage({super.key, this.openInboxOnStart = false});

  final bool openInboxOnStart;

  @override
  State<IosMinimalistMessagePage> createState() =>
      _IosMinimalistMessagePageState();
}

class _IosMinimalistMessagePageState extends State<IosMinimalistMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _classesScrollController = ScrollController();
  bool _showFullPageButton = false;

  @override
  void initState() {
    super.initState();
    _classesScrollController.addListener(_handleClassesScroll);
    if (widget.openInboxOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final filtered = _filteredConversations();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _InboxPage(conversations: filtered),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _classesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleClassesScroll() {
    const double showThreshold = 80.0;
    final offset = _classesScrollController.offset;
    if (!_showFullPageButton && offset > showThreshold) {
      setState(() {
        _showFullPageButton = true;
      });
    } else if (_showFullPageButton && offset < 20.0) {
      setState(() {
        _showFullPageButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color background = Colors.white;
    final List<_Conversation> filtered = _filteredConversations();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Main column with hero + scrollable classes
            Column(
              children: [
                Builder(
                  builder: (context) {
                    final mediaQuery = MediaQuery.of(context);
                    return _SpotifyStyleHero(
                      topPadding: mediaQuery.padding.top,
                      onInboxTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _InboxPage(conversations: filtered),
                          ),
                        );
                      },
                      onCreateClassTap: () {
                        _handleCreateClass(context);
                      },
                      onJoinClassTap: () {
                        _handleJoinClass(context);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _classesScrollController,
                    physics: const BouncingScrollPhysics(),
                    child: const _ClassesExperience(
                      showSearchAndJoin: false,
                    ),
                  ),
                ),
              ],
            ),
            // Floating "open in full page" button that appears after scrolling
            if (_showFullPageButton)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 6,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const _FullPageClassesScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Open in full page',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_Conversation> _filteredConversations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _demoConversations;
    return _demoConversations
        .where(
          (conversation) =>
              conversation.name.toLowerCase().contains(query) ||
              conversation.lastMessage.toLowerCase().contains(query),
        )
        .toList();
  }
}
