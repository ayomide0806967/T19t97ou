import 'package:flutter/material.dart';

class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SubscribeScreen());
  }

  void _showPlanSheet(BuildContext context, {required String planName}) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        Widget optionCard({
          required String title,
          required String priceLine,
          required String subLine,
          required bool selected,
          Widget? trailing,
        }) {
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFFB066)
                    : theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.25),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF25D366),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        priceLine,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  trailing,
                ],
              ],
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  planName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                optionCard(
                  title: 'Annual plan   SAVE 15%',
                  priceLine: 'NGN 6,400.00 / month',
                  subLine: '₦76,800.00 per year, billed annually',
                  selected: false,
                ),
                const SizedBox(height: 10),
                optionCard(
                  title: 'Monthly plan',
                  priceLine: 'NGN 7,600.00 / month',
                  subLine: '₦91,200.00 per year, billed monthly',
                  selected: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Switch plan'),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                          : const Color(0xFFCBD5E1),
                      width: 1.6,
                    ),
                  ),
                  child: Text(
                    'By subscribing, you agree to our Purchaser Terms of Service. '
                    'Subscription auto-renews until cancelled. Cancel at any time, '
                    'at least 24 hours prior to renewal to avoid additional charges. '
                    'Manage your subscription through the platform you subscribed on.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color pageBg =
        isDark ? theme.colorScheme.surface : const Color(0xFFF3F4F6);

    Widget planTab(
      String label, {
      required bool selected,
      bool connectToCard = false,
      String? price,
    }) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFF6B7280),
          borderRadius: connectToCard
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 8,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
                fontFamilyFallback: const [
                  'SF Pro Display',
                  'SF Pro Text',
                  'Roboto',
                ],
                color: Colors.white,
              ),
            ),
            if (price != null) ...[
              const SizedBox(width: 10),
              Text(
                price,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  fontFamilyFallback: const [
                    'SF Pro Display',
                    'SF Pro Text',
                    'Roboto',
                  ],
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
            if (selected) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget planSection({
      required String planName,
      required bool selected,
      required List<Widget> features,
      required Widget action,
      required String price,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: planTab(
              planName,
              selected: selected,
              connectToCard: true,
              price: price,
            ),
          ),
          Card(
            elevation: 0,
            color: isDark ? theme.colorScheme.surface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              side: BorderSide(
                color:
                    theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...features,
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: action),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget featureRow(String left, String right, {Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Text(
                right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Subscribe'),
        backgroundColor: pageBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          planSection(
            planName: 'Basic',
            selected: true,
            price: '₦0',
            features: [
              Text(
                'Enhanced Experience',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              featureRow('Ads', 'No reduction'),
              featureRow('Reply boost', 'Smallest'),
              featureRow(
                'Radar',
                '',
                trailing: Icon(
                  Icons.lock_outline_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              featureRow(
                'Edit post',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Longer posts',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Background video playback',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Download videos',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
            ],
            action: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Colors.black, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showPlanSheet(context, planName: 'Basic'),
              child: const Text('Manage subscription'),
            ),
          ),
          const SizedBox(height: 16),
          planSection(
            planName: 'Standard',
            selected: false,
            price: '₦4,999',
            features: [
              Text(
                'More Control',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              featureRow('Ads', 'Reduced'),
              featureRow('Reply boost', 'Medium'),
              featureRow(
                'Radar',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Edit post',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Longer posts',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Background video playback',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Download videos',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
            ],
            action: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Colors.black, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showPlanSheet(context, planName: 'Standard'),
              child: const Text('Get Standard'),
            ),
          ),
          const SizedBox(height: 16),
          planSection(
            planName: 'Premium',
            selected: false,
            price: '₦9,999',
            features: [
              Text(
                'Best Experience',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              featureRow('Ads', 'Most reduced'),
              featureRow('Reply boost', 'Largest'),
              featureRow(
                'Radar',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Edit post',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Longer posts',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Background video playback',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Download videos',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
            ],
            action: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Colors.black, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showPlanSheet(context, planName: 'Premium'),
              child: const Text('Get Premium'),
            ),
          ),
          const SizedBox(height: 16),
          planSection(
            planName: 'Premium+',
            selected: false,
            price: '₦14,999',
            features: [
              Text(
                'Ultimate Experience',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              featureRow('Ads', 'Least'),
              featureRow('Reply boost', 'Maximum'),
              featureRow(
                'Radar',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Edit post',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Longer posts',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Background video playback',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
              featureRow(
                'Download videos',
                '',
                trailing: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF25D366),
                ),
              ),
            ],
            action: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Colors.black, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showPlanSheet(context, planName: 'Premium+'),
              child: const Text('Get Premium+'),
            ),
          ),
        ],
      ),
    );
  }
}
