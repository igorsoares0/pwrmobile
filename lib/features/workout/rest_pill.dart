import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import 'rest_timer.dart';

/// The rest countdown, as something that floats over the workout instead of
/// pushing it around.
///
/// It used to be a card in the screen's `Column`, which meant the layout jumped
/// upwards at the exact moment the user's thumb came off the checkmark — the
/// one instant it must not move. Here it is drawn in a [Stack] above the list,
/// so nothing below it ever shifts.
///
/// Its own appearance is animated rather than instant, for the same reason:
/// something that materialises under a finger reads as a glitch, something that
/// rises into place reads as a response.
class RestPill extends ConsumerWidget {
  const RestPill({super.key});

  /// How much room the pill needs. Screens that place it over a scroll view
  /// reserve this at the bottom of the scroll, so the last row is reachable
  /// while resting and the padding never changes.
  static const double reservedHeight = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rest = ref.watch(restTimerProvider);

    return AnimatedSwitcher(
      duration: PwrDuration.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: rest.isActive ? const _Pill() : const SizedBox.shrink(),
    );
  }
}

class _Pill extends ConsumerWidget {
  const _Pill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rest = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);

    final label = switch (rest) {
      RestTimerState(isFinished: true) => l10n.workoutRestDone,
      RestTimerState(running: false) => l10n.workoutRestPaused,
      _ => l10n.workoutRest,
    };

    return PwrCard(
      borderRadius: PwrRadius.cardLargeAll,
      padding: const EdgeInsets.symmetric(
        horizontal: PwrSpacing.md,
        vertical: PwrSpacing.sm,
      ),
      child: Row(
        children: [
          RestRing(
            // Draining, not filling. Mid-rest the number that matters is how
            // much is left, and the ring should say the same thing the digits
            // inside it say.
            value: rest.isActive
                ? rest.remaining.inMilliseconds / rest.total.inMilliseconds
                : 0,
            time: formatClock(rest.remaining),
            running: rest.running,
            finished: rest.isFinished,
            // Pausing lives on the ring itself rather than on a third button:
            // it is the least-used of the three actions, and the ring is a
            // 56dp target that was already sitting there doing nothing.
            onTap: rest.isFinished
                ? null
                : (rest.running ? notifier.pause : notifier.resume),
            tooltip: rest.running
                ? l10n.workoutRestPause
                : l10n.workoutRestResume,
          ),
          const SizedBox(width: PwrSpacing.sm),
          Expanded(
            child: PwrOverline(
              label,
              wide: true,
            ),
          ),
          // Both stay visible. Resting is a suggestion, and someone who wants
          // to go straight into the next set must not have to open something
          // first to say so.
          PwrButton.ghost(
            label: l10n.workoutRestAdd,
            size: PwrButtonSize.compact,
            expand: false,
            onPressed: () => notifier.extend(30),
          ),
          PwrButton.ghost(
            label: l10n.workoutRestSkip,
            size: PwrButtonSize.compact,
            expand: false,
            onPressed: notifier.skip,
          ),
        ],
      ),
    );
  }
}

/// The countdown ring, with the clock inside it.
///
/// Public because the shell's session bar shows the same ring: a rest running
/// on the workout screen and a rest running behind three other tabs are the
/// same fact, and they should not be drawn by two different widgets that can
/// drift apart.
class RestRing extends StatelessWidget {
  const RestRing({
    super.key,
    required this.value,
    required this.time,
    required this.running,
    required this.finished,
    required this.tooltip,
    this.onTap,
    this.diameter = 56,
  });

  /// Fraction of the rest still to go, 0..1.
  final double value;

  final String time;
  final bool running;
  final bool finished;
  final String tooltip;
  final VoidCallback? onTap;

  /// Smaller in the session bar than on the workout screen, where it is the
  /// only thing on the row worth looking at.
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final color = finished
        ? PwrColors.textMuted
        : running
        ? PwrColors.accent
        : PwrColors.textMuted;

    final ring = SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tweened over exactly one second, on the default linear curve: the
          // notifier ticks once a second, and anything shorter would make the
          // ring lurch and wait instead of sweeping.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: value, end: value.clamp(0.0, 1.0)),
            duration: running ? const Duration(seconds: 1) : PwrDuration.fast,
            builder: (context, animated, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: animated,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: PwrColors.surfaceRaised,
              ),
            ),
          ),
          Text(
            time,
            style: PwrTypography.metricXs.copyWith(
              fontSize: diameter < 50 ? 11 : 13,
              color: finished ? PwrColors.textPrimary : color,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return ring;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: ring),
        ),
      ),
    );
  }
}
