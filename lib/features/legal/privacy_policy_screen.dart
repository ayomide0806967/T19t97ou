import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/brand_mark.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color _background = Color(0xFFF7F4EC);
  static const Color _headerBackground = Color(0xFFFF8A3B);
  static const Color _divider = Color(0xFFE3DDD3);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _teal = Color(0xFFFF8A3B);

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );

    final titleStyle = GoogleFonts.dmSerifDisplay(
      fontSize: 34,
      height: 1.05,
      color: _textPrimary,
      fontWeight: FontWeight.w500,
    );

    final hubTitleStyle = GoogleFonts.dmSerifDisplay(
      fontSize: 30,
      height: 1.05,
      color: Colors.white,
      fontWeight: FontWeight.w500,
    );

    final bodyStyle = GoogleFonts.inter(
      fontSize: 13.5,
      height: 1.6,
      color: _textSecondary,
      fontWeight: FontWeight.w400,
    );

    final sectionTitleStyle = GoogleFonts.inter(
      fontSize: 12,
      height: 1.25,
      letterSpacing: 0.6,
      color: _textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Theme(
      data: lightTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: _background,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Row(
                    children: [
                      const BrandMark(
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'institution',
                        style: GoogleFonts.inter(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _divider),
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: _textPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: _headerBackground,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                child: Column(
                  children: [
                    Text(
                      'Institution Legal Hub',
                      textAlign: TextAlign.center,
                      style: hubTitleStyle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Information related to our terms of service, policies, intellectual property, and compliance.',
                      textAlign: TextAlign.center,
                      style: bodyStyle.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _HubTile(title: 'Legal overview'),
              _HubTile(title: 'Platform User Terms'),
              _HubTile(title: 'Enterprise & Developer Terms'),
              _HubTile(title: 'Partner & Promotion Terms'),
              _HubTile(title: 'Policies & Guidelines'),
              _HubTile(title: 'Privacy & Data Protection'),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Text(
                  'Institution Privacy Policy',
                  style: titleStyle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Text(
                  'Last updated: January 5th, 2026',
                  style: bodyStyle.copyWith(
                    fontSize: 12.5,
                    color: _textSecondary.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                child: Text(
                  'This Privacy Policy describes how Institution collects, uses, and shares information when you use our mobile application and related services (the “Service”).',
                  style: bodyStyle,
                ),
              ),
              const SizedBox(height: 18),
              _PolicySection(
                title: '1. CHANGES TO THIS PRIVACY POLICY',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We may update this policy from time to time. If we make material changes, we will take reasonable steps to notify you as required by applicable law.',
                  'The “Last updated” date at the top indicates when this policy was most recently revised.',
                ],
              ),
              _PolicySection(
                title: '2. INFORMATION WE COLLECT',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We collect information you provide and information generated through your use of the Service.',
                ],
                bullets: const [
                  'Account information (e.g., name, email, username) and authentication identifiers (including when you sign in with Google).',
                  'User Content you create or upload (e.g., posts, comments, messages, images).',
                  'Usage and device data (e.g., app interactions, device type, operating system, crash logs, and approximate location based on IP address).',
                  'Preferences and settings (e.g., privacy and notification preferences).',
                ],
              ),
              _PolicySection(
                title: '3. HOW WE USE INFORMATION',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We use information to operate, maintain, and improve the Service, including to:',
                ],
                bullets: const [
                  'Provide core features, personalize content, and support your requests.',
                  'Maintain safety and security, prevent abuse, and debug issues.',
                  'Communicate with you about updates, policies, and support.',
                ],
              ),
              _PolicySection(
                title: '4. DISCLOSURE OF YOUR INFORMATION',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We may share information in the following circumstances:',
                ],
                bullets: const [
                  'Service providers who help us operate the Service (e.g., hosting, analytics, payment processing).',
                  'Third-party integrations you choose to use (e.g., authentication providers).',
                  'Legal and safety reasons, such as to comply with law, enforce our terms, or protect users.',
                  'Business transfers, such as a merger, acquisition, or sale of assets.',
                ],
              ),
              _PolicySection(
                title: '5. DATA SECURITY AND RETENTION',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We use reasonable safeguards designed to protect information. No method of transmission or storage is completely secure.',
                  'We retain information for as long as needed to provide the Service and for legitimate business or legal purposes.',
                ],
              ),
              _PolicySection(
                title: '6. YOUR RIGHTS AND CHOICES',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'Depending on where you live, you may have rights regarding your personal information, such as the right to access, delete, or correct it.',
                  'You can also control certain settings in the app, such as privacy and notification preferences.',
                ],
                bullets: const [
                  'Right to access / know',
                  'Right to delete',
                  'Right to correct',
                ],
              ),
              _PolicySection(
                title: '7. CHILDREN’S PRIVACY',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'Institution is not directed to children under 13 (or the minimum age required in your jurisdiction). We do not knowingly collect personal information from children under that age.',
                ],
              ),
              _PolicySection(
                title: '8. HOW TO CONTACT US',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'If you have questions about this Privacy Policy, contact us at privacy@institution.app.',
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Divider(color: _divider, height: 28),
              ),
              const _Footer(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(
            title,
            style: GoogleFonts.inter(
              color: PrivacyPolicyScreen._textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: const Icon(
            Icons.keyboard_arrow_down,
            color: PrivacyPolicyScreen._textSecondary,
          ),
          onTap: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Divider(
            color: PrivacyPolicyScreen._divider,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.titleStyle,
    required this.bodyStyle,
    required this.paragraphs,
    this.bullets = const [],
  });

  final String title;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 10),
          for (final paragraph in paragraphs) ...[
            Text(paragraph, style: bodyStyle),
            const SizedBox(height: 12),
          ],
          if (bullets.isNotEmpty) ...[
            for (final bullet in bullets) ...[
              _Bullet(text: bullet, style: bodyStyle),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: PrivacyPolicyScreen._textSecondary.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final headingStyle = GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: PrivacyPolicyScreen._textPrimary,
    );
    final linkStyle = GoogleFonts.inter(
      fontSize: 13,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: PrivacyPolicyScreen._textSecondary.withValues(alpha: 0.92),
    );

    Widget group(String title, List<String> items) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: headingStyle),
            const SizedBox(height: 10),
            for (final item in items) ...[
              Text(item, style: linkStyle),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    Widget badge(String label) {
      return Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          group('Company', const [
            'Careers',
            'Press inquiries',
            'Brand guidelines',
            'Privacy policy',
            'Security',
            'Terms & conditions',
          ]),
          group('Resources', const [
            'Getting started',
            'Help center',
            'Changelog',
            'Give feedback',
          ]),
          group('API Platform', const [
            'API overview',
            'API models',
            'API documentation',
            'API FAQs',
            'API terms of service',
          ]),
          group('Follow us', const [
            'X (Twitter)',
            'Discord',
            'Instagram',
            'Threads',
            'LinkedIn',
            'YouTube',
          ]),
          Row(
            children: [
              badge('Download on the\nApp Store'),
              const SizedBox(width: 12),
              badge('Get it on\nGoogle Play'),
            ],
          ),
          const SizedBox(height: 18),
          const Center(
            child: BrandMark(
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '© Copyright 2026 Institution',
              style: GoogleFonts.inter(
                color: PrivacyPolicyScreen._textSecondary.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
