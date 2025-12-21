import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../widgets/swiss_bank_icon.dart';

class LoginEmailEntryScreen extends StatefulWidget {
  const LoginEmailEntryScreen({
    super.key,
    this.showPassword = false,
  });

  final bool showPassword;

  @override
  State<LoginEmailEntryScreen> createState() => _LoginEmailEntryScreenState();
}


class _LoginEmailEntryScreenState extends State<LoginEmailEntryScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _canContinue = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_recomputeContinueState);
  }

  void _recomputeContinueState() {
    final text = _emailController.text.trim();
    final bool next =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (next == _canContinue) return;
    setState(() => _canContinue = next);
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color muted = Colors.black.withValues(alpha: 0.56);
    final Color line = Colors.black.withValues(alpha: 0.10);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkResponse(
              radius: 24,
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: line),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.04),
                                  ),
                                  child: Center(
                                    child: SwissBankIcon(
                                      size: 40,
                                      color: Colors.black,
                                      strokeWidthFactor: 0.09,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'Log in or sign up',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'From classroom notes to viral posts, do it all in one place.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 28),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: widget.showPassword
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: 'Username and Email',
                                  hintStyle: TextStyle(
                                    color:
                                        Colors.black.withValues(alpha: 0.35),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: line),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: line),
                                  ),
                                ),
                              ),
                              if (widget.showPassword) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: line),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: line),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _canContinue
                                      ? () => _showComingSoon(
                                            'Username/password flow coming soon',
                                          )
                                      : null,
                                  style: ButtonStyle(
                                    elevation: const WidgetStatePropertyAll(0),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    backgroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                        if (states.contains(WidgetState.disabled)) {
                                          return const Color(0xFFE5E7EB);
                                        }
                                        return Colors.black;
                                      },
                                    ),
                                    foregroundColor: WidgetStateProperty.resolveWith(
                                      (states) {
                                        if (states.contains(WidgetState.disabled)) {
                                          return Colors.black.withValues(alpha: 0.35);
                                        }
                                        return Colors.white;
                                      },
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(height: 1, color: line),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(height: 1, color: line),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showComingSoon('Google sign in coming soon'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: BorderSide(color: line),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  icon: Image.asset(
                                    'assets/images/google_image.png',
                                    height: 22,
                                    width: 22,
                                  ),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showComingSoon('Facebook sign in coming soon'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1877F2),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color:
                                          const Color(0xFF1877F2).withValues(alpha: 0.9),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.facebook_rounded,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Continue with Facebook',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18, top: 10),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: (theme.textTheme.bodySmall ??
                                      const TextStyle(fontSize: 12))
                                  .copyWith(
                                fontSize: 11,
                                color: Colors.black.withValues(alpha: 0.55),
                                decorationColor:
                                    Colors.black.withValues(alpha: 0.45),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        _showComingSoon('Terms of Use'),
                                ),
                                const TextSpan(text: ' · '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () =>
                                        _showComingSoon('Privacy Policy'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
