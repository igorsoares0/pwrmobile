import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import 'rest_pill.dart';
import 'rest_timer.dart';
import 'workout_providers.dart';

/// The workout in progress, announced from every tab.
///
/// A session used to be visible only as a banner on the home screen, which
/// meant walking to the library to add an exercise took both the session and
/// its running rest countdown off screen while both kept going. This sits
/// above the navigation, the way a music app keeps the thing that is playing
/// in reach of the thumb no matter what else is open.
class ActiveSessionBar extends ConsumerWidget {
  const ActiveSessionBar({super.key, this.onResume});

  /// A session open for longer than this stopped being "in progress" and
  /// started being "left open". Nobody rests for three hours, and a counter
  /// reading 14:32:07 the next morning would be the app stating something
  /// absurd with total confidence.
  static const Duration staleAfter = Duration(hours: 3);

  final void Function(String sessionId)? onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeWorkoutProvider).value;

    return AnimatedSwitcher(
      duration: PwrDuration.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: session == null
          ? const SizedBox.shrink()
          : _Bar(session: session, onResume: onResume),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.session, this.onResume});

  final WorkoutSession session;
  final void Function(String sessionId)? onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final rest = ref.watch(restTimerProvider);
    final elapsed = ref.watch(elapsedProvider(session.startedAt));
    final routineName = ref.watch(activeRoutineNameProvider).value;

    final stale = elapsed >= ActiveSessionBar.staleAfter;

    final status = switch (0) {
      _ when stale => l10n.shellSessionStale(
        _startedAtLabel(session.startedAt.toLocal(), locale),
      ),
      _ when rest.isActive => l10n.shellSessionResting,
      _ => '${formatClock(elapsed)} · ${l10n.shellSessionActive}',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        0,
        PwrSpacing.screenH,
        PwrSpacing.xs,
      ),
      child: PwrCard(
        borderRadius: PwrRadius.rowAll,
        padding: const EdgeInsets.symmetric(
          horizontal: PwrSpacing.sm,
          vertical: PwrSpacing.xs,
        ),
        onTap: onResume == null ? null : () => onResume!(session.id),
        child: Row(
          children: [
            // The countdown takes the leading slot when there is one, because
            // it is the only thing on this bar that is running out.
            if (rest.isActive && !stale)
              RestRing(
                diameter: 40,
                value: rest.remaining.inMilliseconds /
                    rest.total.inMilliseconds,
                time: formatClock(rest.remaining),
                running: rest.running,
                finished: rest.isFinished,
                tooltip: l10n.workoutRest,
              )
            else
              _Dot(stale: stale),
            const SizedBox(width: PwrSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routineName ?? l10n.historyFreestyle,
                    style: PwrTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status.toUpperCase(),
                    style: PwrTypography.tag.copyWith(
                      color: stale ? PwrColors.textMuted : PwrColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: PwrSpacing.xs),
            Tooltip(
              message: l10n.shellSessionResume,
              child: const Icon(
                Icons.chevron_right,
                size: 20,
                color: PwrColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// When the session started, at the coarseness the reader needs: the clock
  /// alone if it was today, the date too if the phone has been in a bag since.
  String _startedAtLabel(DateTime startedAt, String locale) {
    final now = DateTime.now();
    final sameDay = DateUtils.isSameDay(startedAt, now);

    return sameDay
        ? DateFormat.Hm(locale).format(startedAt)
        : DateFormat.MMMd(locale).add_Hm().format(startedAt);
  }
}

/// Stands in for the ring when no rest is running.
class _Dot extends StatelessWidget {
  const _Dot({required this.stale});

  final bool stale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Icon(
          // A left-open session is not a workout happening, and the icon
          // should not claim it is.
          stale ? Icons.pause_circle_outline : Icons.play_arrow_rounded,
          size: stale ? 20 : 22,
          color: stale ? PwrColors.textMuted : PwrColors.accent,
        ),
      ),
    );
  }
}
