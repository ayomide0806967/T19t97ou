import 'package:flutter/material.dart';

/// Reusable hexagon-style compose button used on the home/profile screens.
class HexagonComposeButton extends StatelessWidget {
  const HexagonComposeButton({
    super.key,
    required this.onTap,
    this.showPlus = false,
  });

  final VoidCallback onTap;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    const Color buttonColor = Colors.black;
    final BorderRadius radius = BorderRadius.circular(12);

    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: showPlus
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        Transform.translate(
                          offset: Offset(-8, -6),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
