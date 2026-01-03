import 'package:flutter/material.dart';

class SubscribeScreen extends StatelessWidget {
  const SubscribeScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SubscribeScreen());
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
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (price != null) ...[
              const SizedBox(width: 10),
              Text(
                price,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.92),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage subscription')),
                );
              },
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Get Standard')),
                );
              },
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Get Premium')),
                );
              },
              child: const Text('Get Premium'),
            ),
          ),
        ],
      ),
    );
  }
}
