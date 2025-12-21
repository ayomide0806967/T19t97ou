import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../widgets/swiss_bank_icon.dart';
import 'login_email_entry_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showEmailForm = false;
  bool _cardCollapsed = false;
  bool _isDraggingCard = false;
  double _cardDragOffset = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _expandCard() {
    setState(() {
      _cardCollapsed = false;
      _cardDragOffset = 0;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthRepository>();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await auth.signInWithEmailPassword(email, password);
      } else {
        await auth.signUpWithEmailPassword(email, password);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sign in with Apple is coming soon',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
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
                  final double bottomOffset =
                      _cardCollapsed ? hiddenBottom : -clampedDragOffset;

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
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.max,
                                    children: _showEmailForm
                                        ? _buildEmailForm(theme)
                                        : _buildGetStarted(theme),
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
                                  shadowColor:
                                      const Color(0xFF111827).withValues(alpha: 0.18),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color:
                                        const Color(0xFF111827).withValues(alpha: 0.08),
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
      Text(
        'Get Started',
        style: theme.textTheme.headlineSmall,
      ),
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
                      builder: (_) => const LoginEmailEntryScreen(
                        showPassword: true,
                      ),
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
                      builder: (_) => const LoginEmailEntryScreen(
                        showPassword: false,
                      ),
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

  List<Widget> _buildEmailForm(ThemeData theme) {
    return <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: SwissBankIcon(size: 34),
      ),
      const SizedBox(height: 10),
      Text(
        _isLogin ? 'Continue with Email' : 'Create your account',
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 24),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(
          labelText: 'Email address',
          hintText: 'name@institution.edu',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter your email address';
          }
          final emailRegex = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$');
          if (!emailRegex.hasMatch(value)) {
            return 'Provide a valid email address';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'At least 6 characters',
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 28),
      SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isLogin ? 'Continue' : 'Create account'),
        ),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _isLoading
            ? null
            : () => setState(() {
                  _showEmailForm = false;
                }),
        child: const Text('Back to other options'),
      ),
      TextButton(
        onPressed: _isLoading
            ? null
            : () => setState(() {
                  _isLogin = !_isLogin;
                }),
        child: Text(
          _isLogin ? 'Need an account? Create one' : 'Have an account? Sign in',
        ),
      ),
    ];
  }

}

class _InstitutionBackground extends StatefulWidget {
  const _InstitutionBackground({required this.cardCollapsed});

  final bool cardCollapsed;

  @override
  State<_InstitutionBackground> createState() => _InstitutionBackgroundState();
}

class _InstitutionBackgroundState extends State<_InstitutionBackground> {
  static const _messages = <_InstitutionHeroMessage>[
    _InstitutionHeroMessage(
      text: 'IN INSTITUTION',
      accent: Color(0xFFFFFFFF),
      icon: null,
    ),
    _InstitutionHeroMessage(
      text: "The world's first social media school",
      accent: Color(0xFF5EEAD4),
      icon: Icons.public_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'You own a full class',
      accent: Color(0xFF93C5FD),
      icon: Icons.groups_2_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'Create a live quiz exam',
      accent: Color(0xFFFCA5A5),
      icon: Icons.wifi_tethering_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'Create class notes',
      accent: Color(0xFFC4B5FD),
      icon: Icons.note_alt_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'Monitor live quiz exam',
      accent: Color(0xFF67E8F9),
      icon: Icons.monitor_heart_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'Post your ideas and go viral',
      accent: Color(0xFFFDE68A),
      icon: Icons.trending_up_outlined,
    ),
    _InstitutionHeroMessage(
      text: 'Enjoy global visibility',
      accent: Color(0xFF93C5FD),
      icon: Icons.lightbulb_outline,
    ),
  ];

  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111827),
            Color(0xFF0B1220),
          ],
        ),
      ),
    );

    final bool showStronger = widget.cardCollapsed;
    final message = _messages[_index];
    final double textOpacity = showStronger ? 0.96 : 0.88;
    final Color accent = message.accent;
    final TextStyle titleStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0.2,
        ) ??
        TextStyle(
          fontSize: 34,
          color: Colors.white.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w800,
          height: 1.05,
        );
    final TextStyle subtitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.25,
        ) ??
        TextStyle(
          fontSize: 18,
          color: Colors.white.withValues(alpha: 0.72),
          fontWeight: FontWeight.w600,
          height: 1.25,
        );

    return Stack(
      children: [
        Positioned.fill(child: base),
        // Soft accent glows (mature, low-contrast) that shift with the message.
        Positioned(
          top: -120,
          left: -140,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -160,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
              child: IgnorePointer(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  alignment: showStronger
                  ? const Alignment(0, -0.34)
                  : const Alignment(0, -0.48),
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 88),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    );
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: Column(
                    key: ValueKey(_index),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.text.toUpperCase() == 'IN INSTITUTION')
                        SwissBankIcon(
                          size: 76,
                          color: accent.withValues(alpha: 0.92),
                          strokeWidthFactor: 0.085,
                        ),
                      if (message.text.toUpperCase() == 'IN INSTITUTION')
                        const SizedBox(height: 12),
                      _InstitutionHeroText(
                        text: message.text,
                        accent: accent,
                        titleStyle: titleStyle,
                        subtitleStyle: subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstitutionHeroMessage {
  const _InstitutionHeroMessage({
    required this.text,
    required this.accent,
    required this.icon,
  });

  final String text;
  final Color accent;
  final IconData? icon;
}

class _InstitutionHeroText extends StatelessWidget {
  const _InstitutionHeroText({
    required this.text,
    required this.accent,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final String text;
  final Color accent;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    if (text.toUpperCase() == 'IN INSTITUTION') {
      return _OutlinedText(
        text: 'IN INSTITUTION',
        fill: Colors.white,
        stroke: Colors.black,
        style: titleStyle.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      );
    }

    final words = text.split(' ');
    final String highlight = words.isNotEmpty ? words.first : text;
    final String rest = words.length > 1 ? text.substring(highlight.length) : '';

    final bool hideSubtitle =
        text.toLowerCase() == "the world's first social media school";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: highlight,
                style: titleStyle.copyWith(color: accent.withValues(alpha: 0.98)),
              ),
              TextSpan(text: rest, style: titleStyle),
            ],
          ),
        ),
        if (!hideSubtitle) ...[
          const SizedBox(height: 8),
          Text(
            'IN INSTITUTION',
            textAlign: TextAlign.center,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText({
    required this.text,
    required this.fill,
    required this.stroke,
    required this.style,
  });

  final String text;
  final Color fill;
  final Color stroke;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final strokeStyle = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = stroke.withValues(alpha: 0.75),
    );

    final fillStyle = style.copyWith(
      color: fill,
      foreground: null,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, textAlign: TextAlign.center, style: strokeStyle),
        Text(text, textAlign: TextAlign.center, style: fillStyle),
      ],
    );
  }
}
