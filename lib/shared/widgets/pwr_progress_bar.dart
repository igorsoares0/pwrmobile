import 'package:flutter/widgets.dart';

import '../../app/theme/theme.dart';

/// The thin accent bar that shows how far into a workout the user is.
class PwrProgressBar extends StatelessWidget {
  const PwrProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color = PwrColors.accentStrong,
    this.trackColor = PwrColors.surfaceRaised,
  });

  /// Completion in the range 0..1. Values outside the range are clamped.
  final double value;

  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: PwrRadius.pillAll,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: trackColor)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: PwrDuration.normal,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: PwrRadius.pillAll,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
