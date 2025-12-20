import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/simple_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/swiss_bank_icon.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SimpleAuthService _authService = SimpleAuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await _authService.signIn(email, password);
      } else {
        await _authService.signUp(email, password);
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
      await _authService.signInWithGoogle();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cardHeight = constraints.maxHeight * 0.5;
              const double cardRadius = 56;

              return Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF111827),
                            Color(0xFF0B1220),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: cardHeight,
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGetStarted(ThemeData theme) {
    return <Widget>[
      const Spacer(),
      const Align(
        alignment: Alignment.centerLeft,
        child: SwissBankIcon(size: 28),
      ),
      const SizedBox(height: 10),
      Text(
        'Get Started',
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Swiss helps you think, write, and create at your highest level.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF111827).withValues(alpha: 0.62),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _signInWithApple,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: const Icon(Icons.apple),
          label: const Text('Continue with Apple'),
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
              : () => setState(() {
                    _showEmailForm = true;
                  }),
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
        child: SwissBankIcon(size: 28),
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

class _FeatureTag extends StatelessWidget {
  const _FeatureTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600),
      backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }
}
