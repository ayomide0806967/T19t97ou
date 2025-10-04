import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/simple_auth_service.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const [
                            _FeatureTag('Minimal UI'),
                            _FeatureTag('Built for teams'),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Campus conversations, reimagined.',
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A lightweight social hub for announcements, collaborations, and the everyday pulse of your institution.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 56),
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppTheme.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isLogin ? 'Sign in to continue' : 'Create your account',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Use your institutional email to stay connected with the community.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 28),
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
                                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
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
                                        : Text(_isLogin ? 'Sign in' : 'Create account'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _signInWithGoogle,
                                    icon: const Icon(Icons.g_mobiledata, size: 28),
                                    label: const Text('Continue with Google'),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => setState(() {
                                            _isLogin = !_isLogin;
                                          }),
                                  child: Text(
                                    _isLogin
                                        ? 'Need an account? Create one'
                                        : 'Have an account? Sign in',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const [
                            _FeatureTag('Real-time updates'),
                            _FeatureTag('Zero clutter'),
                            _FeatureTag('Secure by default'),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
