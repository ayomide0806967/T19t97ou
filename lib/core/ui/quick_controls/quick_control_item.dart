import 'package:flutter/widgets.dart';

class QuickControlItem {
  const QuickControlItem({
    required this.icon,
    required this.label,
    this.onPressed,
  }) : isTogglable = false,
       onToggle = null,
       initialValue = false;

  const QuickControlItem.toggle({
    required this.icon,
    required this.label,
    required this.onToggle,
    this.initialValue = false,
  }) : isTogglable = true,
       onPressed = null;

  final IconData icon;
  final String label;

  final Future<void> Function()? onPressed;
  final Future<void> Function(bool)? onToggle;

  final bool isTogglable;
  final bool initialValue;
}
