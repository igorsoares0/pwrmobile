import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../workout/summary_providers.dart';

/// The image a finished workout is shared as (spec §16).
///
/// Rendered as a widget and captured locally — never assembled on a server.
/// The whole point of the app is that a session belongs to the device it was
/// logged on, and a share card that needed a round trip would contradict that
/// the one time the user most wants to act.
///
/// Fixed logical size so the exported PNG is the same on every device: a card
/// that reflowed to the phone's width would produce a different image for
/// every user.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.summary});

  final WorkoutSummary summary;

  /// Logical size of the exported image, at 1:1. Portrait 4:5, which is what
  /// social feeds crop least.
  static const Size logicalSize = Size(360, 450);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final stats = summary.stats;
    final load = formatLoad(stats.volume, locale, compact: false);

    const onAccentMuted = Color(0xB3FFFFFF);

    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: PwrColors.accentStrong),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PWR',
                style: PwrTypography.wordmark.copyWith(
                  fontSize: 18,
                  color: PwrColors.onAccent,
                ),
              ),
              const SizedBox(height: PwrSpacing.xxl),

              Text(
                (summary.routineName ?? l10n.shareCardFreestyle).toUpperCase(),
                style: PwrTypography.overlineWide.copyWith(
                  color: onAccentMuted,
                ),
              ),
              const SizedBox(height: PwrSpacing.sm),

              Text.rich(
                TextSpan(
                  text: load.value,
                  children: [
                    TextSpan(
                      text: ' ${load.unit.toUpperCase()}',
                      style: PwrTypography.metricXl.copyWith(
                        fontSize: 18,
                        color: onAccentMuted,
                      ),
                    ),
                  ],
                ),
                style: PwrTypography.metricXl.copyWith(
                  color: PwrColors.onAccent,
                ),
              ),

              const Spacer(),

              if (summary.performed.isNotEmpty) ...[
                Text(
                  l10n.shareCardBest.toUpperCase(),
                  style: PwrTypography.metricCaption.copyWith(
                    color: onAccentMuted,
                  ),
                ),
                const SizedBox(height: PwrSpacing.xs),
                _BestSet(summary: summary, locale: locale),
                const SizedBox(height: PwrSpacing.lg),
              ],

              const Divider(color: onAccentMuted, height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Figure(
                    value: '${stats.completedSetCount}',
                    caption: l10n.shareCardSets,
                  ),
                  const SizedBox(width: 26),
                  _Figure(
                    value: '${roundedMinutes(stats.duration ?? Duration.zero)}',
                    caption: l10n.shareCardMinutes,
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMd(
                      locale,
                    ).format(stats.session.startedAt.toLocal()).toUpperCase(),
                    style: PwrTypography.metricCaption.copyWith(
                      color: onAccentMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestSet extends StatelessWidget {
  const _BestSet({required this.summary, required this.locale});

  final WorkoutSummary summary;
  final String locale;

  @override
  Widget build(BuildContext context) {
    // The spec's mock says "NEW PR". Personal records need the phase 5
    // `PersonalRecord` table, so the card shows the session's heaviest set
    // instead — true today, and the same shape of brag.
    final detail = summary.performed.reduce((a, b) {
      final best = WorkoutSummary.bestSetOf(a)?.weight ?? 0;
      final other = WorkoutSummary.bestSetOf(b)?.weight ?? 0;
      return other > best ? b : a;
    });

    final best = WorkoutSummary.bestSetOf(detail);
    if (best == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.exercise.name,
          style: PwrTypography.titleLarge.copyWith(color: PwrColors.onAccent),
        ),
        const SizedBox(height: 2),
        Text(
          _label(best, locale),
          style: PwrTypography.metricMd.copyWith(color: PwrColors.onAccent),
        ),
      ],
    );
  }

  String _label(WorkoutSet best, String locale) {
    final reps = best.reps ?? 0;
    final weight = best.weight;
    if (weight == null || weight == 0) return '$reps';
    return '${formatLoad(weight, locale).value} KG × $reps';
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: PwrTypography.metricMd.copyWith(
            fontSize: 19,
            color: PwrColors.onAccent,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          caption.toUpperCase(),
          style: PwrTypography.metricCaption.copyWith(
            color: const Color(0xB3FFFFFF),
          ),
        ),
      ],
    );
  }
}
