import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../../legal/privacy_policy_screen.dart';
import '../../legal/terms_of_service_screen.dart';
import '../../../widgets/brand_mark.dart';
import '../../../widgets/swiss_bank_icon.dart';
import 'login_email_entry_screen.dart';

part 'login_screen_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _cardCollapsed = true;
  bool _isDraggingCard = false;
  double _cardDragOffset = 0;
  double _sliderProgress = 0;
  int _bannerIndex = 0;

  @override
  void dispose() {
    super.dispose();
  }

  void _expandCard() {
    setState(() {
      _cardCollapsed = false;
      _cardDragOffset = 0;
      _bannerIndex = 0;
    });
  }

  void _collapseCard() {
    setState(() {
      _cardCollapsed = true;
      _cardDragOffset = 0;
      _sliderProgress = 0;
      _bannerIndex = 0;
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

  void _openTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
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
                child: _CometBackground(
                  cardCollapsed: _cardCollapsed,
                  pageIndex: _cardCollapsed
                      ? (_sliderProgress <= 0.01 ? 0 : 1)
                      : (1 + _bannerIndex.clamp(0, 4)),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardHeight = math.min(
                    constraints.maxHeight * 0.54,
                    520,
                  );
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
                      if (!_cardCollapsed)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Align(
                              alignment: const Alignment(0, -0.48),
                              child: _AnimatedPromoBanner(
                                onIndexChanged: (index) {
                                  setState(() {
                                    _bannerIndex = index;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
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
                                      _collapseCard();
                                    } else {
                                      _cardDragOffset = 0;
                                    }
                                  });
                                },
                          child: Material(
                            color: const Color(0xFFF3F4F6),
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
                      if (!_cardCollapsed)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: cardHeight + bottomOffset,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _collapseCard,
                          ),
                        ),
	                      if (_cardCollapsed)
	                        Positioned.fill(
	                          child: SafeArea(
	                            top: false,
	                            child: Align(
	                              alignment: const Alignment(0, -0.05),
	                              child: Padding(
	                                padding: const EdgeInsets.symmetric(
	                                  horizontal: 24,
	                                ),
                                child: _OnboardingCenterBlock(
                                  enabled: !isLoading,
                                  onStarted: _expandCard,
                                  onProgress: (value) {
                                    setState(() {
                                      _sliderProgress = value;
                                    });
                                  },
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
    final policyStyle = theme.textTheme.bodySmall?.copyWith(
      color: const Color(0xFF6B7280),
      height: 1.35,
    );
    final policyLinkStyle = policyStyle?.copyWith(
      color: const Color(0xFF111827).withValues(alpha: 0.88),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF111827).withValues(alpha: 0.35),
      fontWeight: FontWeight.w600,
    );
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
      Text.rich(
        TextSpan(
          style: policyStyle,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: policyLinkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = isLoading ? null : _openTermsOfService,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: policyLinkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = isLoading ? null : _openPrivacyPolicy,
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

class _OnboardingCenterBlock extends StatelessWidget {
  const _OnboardingCenterBlock({
    required this.enabled,
    required this.onStarted,
    this.onProgress,
  });

  final bool enabled;
  final VoidCallback onStarted;
  final ValueChanged<double>? onProgress;

  static const Color _logoOrange = Color(0xFFFF8A3B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.displaySmall?.copyWith(
          fontSize: 62,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.94),
          letterSpacing: -1.4,
          height: 0.95,
        );

    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.46),
          height: 1.35,
        );

    final policyBase = theme.textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          color: Colors.white.withValues(alpha: 0.44),
          height: 1.35,
        );
    final policyLink = policyBase?.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.44),
      color: Colors.white.withValues(alpha: 0.58),
      fontWeight: FontWeight.w600,
    );

    return _OnboardingTitleAndSlider(
      enabled: enabled,
      onStarted: onStarted,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      policyBase: policyBase,
      policyLink: policyLink,
      onProgress: onProgress,
    );
  }
}

class _OnboardingTitleAndSlider extends StatefulWidget {
  const _OnboardingTitleAndSlider({
    required this.enabled,
    required this.onStarted,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.policyBase,
    required this.policyLink,
    this.onProgress,
  });

  final bool enabled;
  final VoidCallback onStarted;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? policyBase;
  final TextStyle? policyLink;
  final ValueChanged<double>? onProgress;

  @override
  State<_OnboardingTitleAndSlider> createState() =>
      _OnboardingTitleAndSliderState();
}

class _OnboardingTitleAndSliderState extends State<_OnboardingTitleAndSlider> {
  static const Color _logoOrange = Color(0xFFFF8A3B);
  double _progress = 0;

  void _openTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'institution';
    final base = widget.titleStyle;
    final effectiveTitle = base ??
        Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: 62,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.94),
              letterSpacing: -1.4,
              height: 0.95,
            );

    final int total = title.length;
    final clamped = _progress.clamp(0.0, 1.0);
    final coloredCount = (clamped * total).round().clamp(0, total);

    final spans = <InlineSpan>[];
    for (var i = 0; i < total; i++) {
      final ch = title[i];
      final isColored = i < coloredCount;
      spans.add(
        TextSpan(
          text: ch,
          style: effectiveTitle?.copyWith(
            color: isColored
                ? _logoOrange
                : Colors.white.withValues(alpha: 0.92),
          ),
        ),
      );
    }

    final subtitleStyle = widget.subtitleStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.46),
              height: 1.35,
            );

    final policyBase = widget.policyBase ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.44),
              height: 1.35,
            );
    final policyLink = widget.policyLink ??
        policyBase?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.44),
          color: Colors.white.withValues(alpha: 0.58),
          fontWeight: FontWeight.w600,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 74),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'From classroom notes to viral posts',
          textAlign: TextAlign.center,
          style: subtitleStyle,
        ),
        const SizedBox(height: 40),
        _SlideToGetStarted(
          enabled: widget.enabled,
          onCompleted: widget.onStarted,
          onProgress: (value) {
            setState(() {
              _progress = value;
            });
            widget.onProgress?.call(value);
          },
        ),
        const SizedBox(height: 28),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: policyBase,
            children: [
              const TextSpan(text: 'By continuing, you agree to the\n'),
              TextSpan(
                text: 'Terms of Service',
                style: policyLink,
                recognizer: TapGestureRecognizer()..onTap = _openTermsOfService,
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: policyLink,
                recognizer: TapGestureRecognizer()..onTap = _openPrivacyPolicy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlideToGetStarted extends StatefulWidget {
  const _SlideToGetStarted({
    required this.enabled,
    required this.onCompleted,
    this.onProgress,
  });

  final bool enabled;
  final VoidCallback onCompleted;
  final ValueChanged<double>? onProgress;

  @override
  State<_SlideToGetStarted> createState() => _SlideToGetStartedState();
}

class _SlideToGetStartedState extends State<_SlideToGetStarted>
    with TickerProviderStateMixin {
  static const double _height = 56;
  static const double _knobSize = 44;
  static const double _padding = 6;
  static const double _completeThreshold = 0.62;

  double _dragX = 0;
  bool _dragging = false;
  bool _completed = false;
  double _progress = 0;

  AnimationController? _pulseController;
  AnimationController? _autoSlideController;

  @override
  void initState() {
    super.initState();
    _pulseController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _autoSlideController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _autoSlideController?.dispose();
    super.dispose();
  }

  Future<void> _complete(double maxDrag) async {
    if (_completed) return;
    setState(() {
      _dragX = maxDrag;
      _completed = true;
      _dragging = false;
    });
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    const Color logoOrange = Color(0xFFFF8A3B);
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        );
    final baseAlpha = widget.enabled ? 0.92 : 0.42;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final trackWidth = math.min(available * 0.75, 300.0);
        final maxDrag = math.max(
          0.0,
          trackWidth - _knobSize - _padding * 2,
        );
        final clamped = _dragX.clamp(0.0, maxDrag);
        // Wave is independent of drag; only disabled when slide is completed.
        final bool canPulse = widget.enabled && !_completed;
        final pulseAnimation =
            _pulseController ?? const AlwaysStoppedAnimation(0.0);
        final autoAnimation =
            _autoSlideController ?? const AlwaysStoppedAnimation(0.0);
        final canAuto = widget.enabled &&
            !_completed &&
            !_dragging &&
            _progress == 0 &&
            _dragX == 0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Only horizontal drag should move the arrow; tap does not auto-slide.
          onTap: null,
          onHorizontalDragStart: widget.enabled
              ? (_) => setState(() => _dragging = true)
              : null,
	          onHorizontalDragUpdate: widget.enabled
	              ? (details) {
	                  if (_completed) return;
	                  setState(() {
	                    _dragX = _dragX + details.delta.dx;
	                    final nextClamped =
	                        (_dragX.clamp(0.0, maxDrag)) as double;
	                    _progress = maxDrag <= 0
	                        ? 0.0
	                        : (nextClamped / maxDrag);
	                  });
	                  widget.onProgress?.call(_progress);
	                }
	              : null,
	          onHorizontalDragEnd: widget.enabled
	              ? (_) async {
	                  if (_completed) return;
	                  setState(() => _dragging = false);
	                  final endClamped =
	                      (_dragX.clamp(0.0, maxDrag)) as double;
	                  final didComplete =
	                      endClamped >= maxDrag * _completeThreshold;
	                  if (!didComplete) {
	                    setState(() {
	                      _dragX = 0;
	                      _progress = 0;
	                    });
	                    widget.onProgress?.call(0.0);
	                    return;
	                  }
	                  setState(() {
	                    _dragX = endClamped;
	                    _progress = 1.0;
	                  });
	                  widget.onProgress?.call(1.0);
	                  await _complete(maxDrag);
	                }
	              : null,
          child: Semantics(
            button: true,
            enabled: widget.enabled,
	            label: 'Slide to get started',
	            child: Center(
	              child: SizedBox(
	                width: trackWidth,
	                height: _height,
	                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D343A).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
	                  child: Stack(
	                    children: [
	                      Positioned.fill(
	                        child: Padding(
	                          padding: const EdgeInsets.only(
	                            left: _padding + _knobSize + 12,
	                            right: 18,
	                          ),
	                          child: Align(
	                            alignment: Alignment.centerLeft,
	                            child: RichText(
	                              text: TextSpan(
	                                children: _buildWordSpans(
	                                  baseStyle,
	                                  baseAlpha,
	                                ),
	                              ),
	                            ),
	                          ),
	                        ),
	                      ),
		                      Positioned(
		                        left: _padding,
		                        top: (_height - _knobSize) / 2,
		                        child: AnimatedBuilder(
		                          animation: Listenable.merge(
		                            <Listenable>[pulseAnimation, autoAnimation],
		                          ),
		                          builder: (context, _) {
		                            final knobOffset = canAuto
		                                ? maxDrag *
		                                    0.08 *
		                                    Curves.easeInOutCubic.transform(
		                                      (autoAnimation as Animation<double>)
	                                              .value,
		                                    )
		                                : clamped;
		                            final pulseT =
		                                (pulseAnimation as Animation<double>).value;
		                            final waveT = 0.5 +
		                                0.5 * math.sin(pulseT * 2 * math.pi);
		                            final waveDiameter =
		                                _knobSize * (1.08 + 0.38 * waveT);
		                            final waveAlpha = canPulse
		                                ? (0.22 * (1.0 - waveT)).clamp(0.0, 0.22)
		                                : 0.0;
		
		                            return Transform.translate(
		                              offset: Offset(knobOffset, 0),
		                              child: SizedBox(
		                                width: _knobSize,
		                                height: _knobSize,
		                                child: Stack(
		                                  clipBehavior: Clip.none,
		                                  alignment: Alignment.center,
		                                  children: [
		                                    if (waveAlpha > 0.001)
		                                      Positioned.fill(
		                                        child: OverflowBox(
		                                          maxWidth: _knobSize * 3,
		                                          maxHeight: _knobSize * 3,
		                                          alignment: Alignment.center,
		                                          child: Container(
		                                            width: waveDiameter,
		                                            height: waveDiameter,
		                                            decoration: BoxDecoration(
		                                              shape: BoxShape.circle,
		                                              border: Border.all(
		                                                color: Colors.white
		                                                    .withValues(
		                                                  alpha: waveAlpha,
		                                                ),
		                                                width: 2,
		                                              ),
		                                            ),
		                                          ),
		                                        ),
		                                      ),
		                                    Container(
		                                      width: _knobSize,
		                                      height: _knobSize,
		                                      decoration: BoxDecoration(
		                                        color: widget.enabled
		                                            ? logoOrange
		                                            : logoOrange.withValues(
		                                                alpha: 0.55,
		                                              ),
		                                        shape: BoxShape.circle,
		                                        boxShadow: const [
		                                          BoxShadow(
		                                            color: Colors.black54,
		                                            blurRadius: 16,
		                                            offset: Offset(0, 8),
		                                          ),
		                                        ],
		                                      ),
		                                      child: Icon(
		                                        Icons.arrow_forward_rounded,
		                                        color: Colors.black.withValues(
		                                          alpha: 0.86,
		                                        ),
		                                        size: 22,
		                                      ),
		                                    ),
		                                  ],
		                                ),
		                              ),
		                            );
		                          },
		                        ),
		                      ),
	                    ],
	                  ),
	                ),
	              ),
	            ),
	          ),
	        );
	      },
	    );
  }

	  List<InlineSpan> _buildWordSpans(
	    TextStyle? baseStyle,
	    double baseAlpha,
	  ) {
    final words = ['Slide', 'to', 'get', 'started'];
    final gaps = [' ', ' ', ' ', ''];
    final spans = <InlineSpan>[];
    final clamped = _progress.clamp(0.0, 1.0);

    for (var i = 0; i < words.length; i++) {
      final start = i / words.length;
      final end = (i + 1) / words.length;
      final t = ((clamped - start) / (end - start)).clamp(0.0, 1.0);
      final alphaFactor = 1.0 - t;
      final style = baseStyle?.copyWith(
        color: Colors.white.withValues(alpha: baseAlpha * alphaFactor),
      );
      spans.add(TextSpan(text: words[i] + gaps[i], style: style));
	    }
	    return spans;
	  }
	}

class _AnimatedPromoBanner extends StatefulWidget {
  const _AnimatedPromoBanner({this.onIndexChanged});

  final ValueChanged<int>? onIndexChanged;

  @override
  State<_AnimatedPromoBanner> createState() => _AnimatedPromoBannerState();
}

class _AnimatedPromoBannerState extends State<_AnimatedPromoBanner> {
  static const List<String> _messages = <String>[
    "The world's first social media school",
    'You own a full class',
    'Monitor live exam',
    'Post your ideas and go viral',
    'Enjoy global visibility',
  ];

  static const Duration _tick = Duration(milliseconds: 70);
  static const int _holdTicks = 22;

  late String _currentMessage;
  int _messageIndex = 0;
  int _charIndex = 0;
  int _holdCounter = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentMessage = _messages[_messageIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onIndexChanged?.call(_messageIndex);
    });
    _timer = Timer.periodic(_tick, _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    setState(() {
      if (_charIndex < _currentMessage.length) {
        _charIndex++;
        return;
      }
      if (_holdCounter < _holdTicks) {
        _holdCounter++;
        return;
      }
      _holdCounter = 0;
      _charIndex = 0;
      _messageIndex = (_messageIndex + 1) % _messages.length;
      _currentMessage = _messages[_messageIndex];
      widget.onIndexChanged?.call(_messageIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _currentMessage.substring(
      0,
      _charIndex.clamp(0, _currentMessage.length),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: _charIndex == 0 ? 0 : 1,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 20,
              height: 1.25,
              letterSpacing: 0.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
