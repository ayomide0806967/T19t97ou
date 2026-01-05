import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../../../widgets/swiss_bank_icon.dart';
import 'login_email_entry_screen.dart';

part 'login_screen_background.dart';
part 'login_screen_hero.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _cardCollapsed = true;
  bool _isDraggingCard = false;
  double _cardDragOffset = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _expandCard() {
    setState(() {
      _cardCollapsed = false;
      _cardDragOffset = 0;
    });
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUi = ref.watch(authControllerProvider);
    final isLoading = authUi.isLoading;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: _InstitutionBackground(cardCollapsed: _cardCollapsed),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardHeight = constraints.maxHeight * 0.5;
                  const double cardRadius = 36;
                  final double hiddenBottom = -cardHeight - 24;
                  final double clampedDragOffset = _cardCollapsed
                      ? 0
                      : _cardDragOffset.clamp(0, cardHeight);
                  final double bottomOffset = _cardCollapsed
                      ? hiddenBottom
                      : -clampedDragOffset;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: _isDraggingCard
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        left: 0,
                        right: 0,
                        bottom: bottomOffset,
                        height: cardHeight,
                        child: GestureDetector(
                          onVerticalDragStart: _cardCollapsed
                              ? null
                              : (_) => setState(() => _isDraggingCard = true),
                          onVerticalDragUpdate: _cardCollapsed
                              ? null
                              : (details) {
                                  setState(() {
                                    _cardDragOffset += details.delta.dy;
                                  });
                                },
                          onVerticalDragEnd: _cardCollapsed
                              ? null
                              : (_) {
                                  // Make it easier to dismiss: any noticeable
                                  // downward drag should collapse the card.
                                  final shouldCollapse =
                                      _cardDragOffset > cardHeight * 0.10;
                                  setState(() {
                                    _isDraggingCard = false;
                                    if (shouldCollapse) {
                                      _cardCollapsed = true;
                                      _cardDragOffset = 0;
                                    } else {
                                      _cardDragOffset = 0;
                                    }
                                  });
                                },
                          child: Material(
                            color: Colors.white,
                            elevation: 18,
                            shadowColor: Colors.black.withValues(alpha: 0.35),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(cardRadius),
                                topRight: Radius.circular(cardRadius),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  20,
                                  20,
                                  12,
                                ),
                                child: Form(
                                  child: ListView(
                                    padding: EdgeInsets.zero,
                                    children: _buildGetStarted(theme),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_cardCollapsed)
                        Positioned(
                          left: 56,
                          right: 56,
                          bottom: 56,
                          child: SafeArea(
                            top: false,
                              child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _expandCard,
                                style: ElevatedButton.styleFrom(
                                  // Off‑white container with dark text
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 6,
                                  shadowColor: const Color(
                                    0xFF111827,
                                  ).withValues(alpha: 0.15),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.10),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Let's get inside",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGetStarted(ThemeData theme) {
    final authUi = ref.watch(authControllerProvider);
    final isLoading = authUi.isLoading;
    return <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: SwissBankIcon(size: 44),
      ),
      const SizedBox(height: 10),
      Text(
        'Sign in to Institution',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: const Color(0xFF111827),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'From classroom notes to viral posts',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF6B7280),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginEmailEntryScreen(showPassword: true),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text('Username and Password'),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithGoogle,
          icon: Image.asset(
            'assets/images/google_image.png',
            height: 36,
            width: 36,
          ),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF111827),
            side: BorderSide(
              color: const Color(0xFF111827).withValues(alpha: 0.10),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginEmailEntryScreen(showPassword: false),
                    ),
                  );
                },
          style: OutlinedButton.styleFrom(
            backgroundColor:
                const Color(0xFF111827).withValues(alpha: 0.06),
            foregroundColor: const Color(0xFF111827),
            side: BorderSide(
              color: const Color(0xFF111827).withValues(alpha: 0.05),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text('Continue with Email'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'By continuing, you agree to our Terms of Use.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFF6B7280),
        ),
      ),
    ];
  }
}
