import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import '../sharing/share_preview_sheet.dart';
import 'summary_providers.dart';

/// What the workout added up to.
///
/// The end of the flow the spec's §23 defines as the MVP success criterion,
/// and the screen the share card (§16) will be cut from.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    this.onClose,
  });

  final String sessionId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(workoutSummaryProvider(sessionId)).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: summary == null
                  ? Center(
                      child: Text(
                        l10n.summaryMissing,
                        style: PwrTypography.bodyLarge,
                      ),
                    )
                  : _Body(summary: summary),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PwrSpacing.screenH,
                0,
                PwrSpacing.screenH,
                PwrSpacing.md,
              ),
              child: Column(
                children: [
                  // Only offered when there is something to brag about: a
                  // session with nothing checked off has no card worth making.
                  if (summary != null && !summary.isEmpty) ...[
                    PwrButton.secondary(
                      label: l10n.shareAction,
                      onPressed: () => SharePreviewSheet.show(context, summary),
                    ),
                    const SizedBox(height: PwrSpacing.cardGap),
                  ],
                  PwrButton(label: l10n.summaryClose, onPressed: onClose),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final minutes = roundedMinutes(summary.stats.duration ?? Duration.zero);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.screenTop,
        PwrSpacing.screenH,
        PwrSpacing.xxl,
      ),
      children: [
        PwrOverline(l10n.summaryComplete(minutes)),
        const SizedBox(height: PwrSpacing.sm),
        Text(
          summary.routineName == null
              ? l10n.summaryTitleNoRoutine
              : l10n.summaryTitle(summary.routineName!),
          style: PwrTypography.displaySmall,
        ),
        const SizedBox(height: PwrSpacing.lg),

        if (summary.isEmpty)
          const _NothingLogged()
        else ...[
          _HeroCard(summary: summary),
          const SizedBox(height: PwrSpacing.xl),
          PwrOverline(l10n.summaryBestToday),
          const SizedBox(height: PwrSpacing.sm),
          for (final detail in summary.performed) _BestRow(detail: detail),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final stats = summary.stats;
    // The headline figure stays exact; `1.150 kg` beats `1,1 t`.
    final load = formatLoad(stats.volume, locale, compact: false);
    final delta = summary.volumeDelta;

    const onAccentMuted = Color(0xB3FFFFFF);

    return PwrCard.accent(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      borderRadius: PwrRadius.cardLargeAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.MMMd(
              locale,
            ).format(stats.session.startedAt.toLocal()).toUpperCase(),
            style: PwrTypography.metricCaption.copyWith(
              color: onAccentMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              text: load.value,
              children: [
                TextSpan(
                  text: ' ${load.unit.toUpperCase()}',
                  style: PwrTypography.metricXl.copyWith(
                    fontSize: 18,
                    color: PwrColors.onAccent,
                  ),
                ),
              ],
            ),
            style: PwrTypography.metricXl.copyWith(color: PwrColors.onAccent),
          ),
          const SizedBox(height: PwrSpacing.sm),
          Text(
            // No comparison invented when there is nothing to compare to: a
            // first session on a routine says so rather than showing +0%.
            delta == null
                ? '${l10n.summaryVolumeCaption} · ${l10n.summaryFirstOnRoutine}'
                : '${l10n.summaryVolumeCaption} · '
                      '${l10n.summaryVsPrevious(_formatDelta(delta, locale))}',
            style: PwrTypography.buttonSmall.copyWith(color: onAccentMuted),
          ),
          const SizedBox(height: PwrSpacing.lg),
          const Divider(color: onAccentMuted, height: 1),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                value: '${stats.completedSetCount}',
                caption: l10n.summaryStatSets,
              ),
              const SizedBox(width: 22),
              _HeroStat(
                value: '${summary.performed.length}',
                caption: l10n.summaryStatExercises,
              ),
              const SizedBox(width: 22),
              _HeroStat(
                value: '${roundedMinutes(stats.duration ?? Duration.zero)}',
                caption: l10n.summaryStatDuration,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Signed percentage, so a gain reads `+12%` rather than an ambiguous `12%`.
  String _formatDelta(double delta, String locale) {
    final percent = NumberFormat('0', locale).format(delta.abs() * 100);
    return '${delta >= 0 ? '+' : '−'}$percent%';
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.caption});

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
        const SizedBox(height: 6),
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

class _BestRow extends ConsumerWidget {
  const _BestRow({required this.detail});

  final WorkoutExerciseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider);
    final locale = Localizations.localeOf(context);
    final best = WorkoutSummary.bestSetOf(detail);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PwrColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              detail.exercise.displayName(catalog, locale.languageCode),
              style: PwrTypography.bodyMedium,
            ),
          ),
          Text(
            _label(l10n, best, locale.toLanguageTag()),
            style: PwrTypography.metricXs.copyWith(color: PwrColors.accent),
          ),
        ],
      ),
    );
  }

  /// Bodyweight movements have no load, so they report reps alone rather than
  /// a misleading `0kg`.
  String _label(AppLocalizations l10n, WorkoutSet? best, String locale) {
    if (best == null) return '—';
    final reps = best.reps ?? 0;
    final weight = best.weight;
    if (weight == null || weight == 0) return l10n.summaryBodyweightSet(reps);
    return l10n.summaryBestSet(formatLoad(weight, locale).value, reps);
  }
}

class _NothingLogged extends StatelessWidget {
  const _NothingLogged();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PwrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.summaryNothingLogged, style: PwrTypography.titleLarge),
          const SizedBox(height: PwrSpacing.xs),
          Text(
            l10n.summaryNothingLoggedBody,
            style: PwrTypography.bodyLarge.copyWith(color: PwrColors.textMuted),
          ),
        ],
      ),
    );
  }
}
