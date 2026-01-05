import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/brand_mark.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                  'Institution Terms of Service',
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
                  'Welcome to Institution. These Terms of Service (“Terms”) govern your access to and use of our mobile application and related services (collectively, the “Service”). By using the Service, you agree to these Terms.',
                  style: bodyStyle,
                ),
              ),
              const SizedBox(height: 18),
              _TermsSection(
                title: '1. CHANGES TO THESE TERMS',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We may modify these Terms from time to time. If we make material changes, we will take reasonable steps to notify you as required by applicable law.',
                  'Your continued use of the Service after the updated Terms become effective constitutes your acceptance of the changes. If you do not agree to the updated Terms, do not continue using the Service.',
                ],
              ),
              _TermsSection(
                title: '2. ACCOUNTS AND SECURITY',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                  'If you believe your account has been compromised, notify us promptly and take steps to secure your account.',
                ],
              ),
              _TermsSection(
                title: '3. LICENSE AND ACCEPTABLE USE',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We grant you a personal, non-transferable, non-exclusive license to access and use the Service in accordance with these Terms.',
                  'You agree not to misuse the Service, including by attempting to access systems without authorization, disrupting the Service, or distributing malware.',
                ],
              ),
              _TermsSection(
                title: '4. YOUR CONTENT',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'You may submit content such as text, images, or other materials (“User Content”). You retain ownership of your User Content.',
                  'You grant Institution a license to host, store, reproduce, and display User Content as necessary to operate, maintain, and improve the Service.',
                ],
              ),
              _TermsSection(
                title: '5. THIRD-PARTY SERVICES',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'The Service may integrate with third-party products or services (for example, authentication providers). Your use of third-party services is subject to their terms and policies.',
                  'We are not responsible for third-party services and do not guarantee their availability, security, or performance.',
                ],
              ),
              _TermsSection(
                title: '6. TERMINATION',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'We may suspend or terminate your access to the Service if we reasonably believe you have violated these Terms or if required by law.',
                  'You may stop using the Service at any time.',
                ],
              ),
              _TermsSection(
                title: '7. DISCLAIMERS',
                titleStyle: sectionTitleStyle,
                bodyStyle: bodyStyle,
                paragraphs: const [
                  'THE SERVICE IS PROVIDED “AS IS” AND “AS AVAILABLE”. TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED.',
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
              color: TermsOfServiceScreen._textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: const Icon(
            Icons.keyboard_arrow_down,
            color: TermsOfServiceScreen._textSecondary,
          ),
          onTap: () {},
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Divider(
            color: TermsOfServiceScreen._divider,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.titleStyle,
    required this.bodyStyle,
    required this.paragraphs,
  });

  final String title;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;
  final List<String> paragraphs;

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
        ],
      ),
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
      color: TermsOfServiceScreen._textPrimary,
    );
    final linkStyle = GoogleFonts.inter(
      fontSize: 13,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: TermsOfServiceScreen._textSecondary.withValues(alpha: 0.92),
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
                color: TermsOfServiceScreen._textSecondary.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
