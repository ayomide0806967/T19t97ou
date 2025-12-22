import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../widgets/swiss_bank_icon.dart';
import 'login_email_entry_screen.dart';

part 'login_screen_background.dart';
part 'login_screen_hero.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _cardCollapsed = false;
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
    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().signInWithGoogle();
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: SafeArea(
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
                                  final shouldCollapse =
                                      _cardDragOffset > cardHeight * 0.35;
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.max,
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
                          left: 20,
                          right: 20,
                          bottom: 12,
                          child: SafeArea(
                            top: false,
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _expandCard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 6,
                                  shadowColor: const Color(
                                    0xFF111827,
                                  ).withValues(alpha: 0.18),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: const Color(
                                      0xFF111827,
                                    ).withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'ENTER IN INSTITUTION',
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
    return <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: SwissBankIcon(size: 34),
      ),
      const SizedBox(height: 10),
      Text('Get Started', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(
        'From classroom notes to viral posts',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF111827).withValues(alpha: 0.62),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading
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
          onPressed: _isLoading ? null : _signInWithGoogle,
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
          onPressed: _isLoading
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
            backgroundColor: const Color(0xFF111827).withValues(alpha: 0.06),
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
          color: const Color(0xFF111827).withValues(alpha: 0.55),
        ),
      ),
    ];
  }
}
