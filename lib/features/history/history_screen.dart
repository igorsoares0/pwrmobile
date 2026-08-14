import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';

/// Finished sessions, newest first, grouped by month.
final historyProvider = StreamProvider<List<WorkoutSessionStats>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchHistory(),
);

/// A run of sessions sharing a calendar month.
class HistoryMonth {
  const HistoryMonth({required this.month, required this.sessions});

  /// The first day of the month, for formatting the heading.
  final DateTime month;
  final List<WorkoutSessionStats> sessions;
}

/// Groups sessions by the month they started in, preserving newest-first order.
///
/// Done in Dart rather than SQL because "which month" depends on the device's
/// time zone, and the database stores UTC — grouping in SQL would put a
/// late-evening workout in the wrong month for anyone west of Greenwich.
List<HistoryMonth> groupByMonth(List<WorkoutSessionStats> sessions) {
  final months = <DateTime, List<WorkoutSessionStats>>{};

  for (final stats in sessions) {
    final local = stats.session.startedAt.toLocal();
    final key = DateTime(local.year, local.month);
    months.putIfAbsent(key, () => []).add(stats);
  }

  return [
    for (final entry in months.entries)
      HistoryMonth(month: entry.key, sessions: entry.value),
  ];
}

/// Every workout the user has finished.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.onOpenSession, this.onBack});

  final void Function(String sessionId)? onOpenSession;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(historyProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PwrSpacing.screenH,
                PwrSpacing.screenTop,
                PwrSpacing.screenH,
                0,
              ),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: PwrSpacing.sm),
                  ],
                  Text(l10n.historyTitle, style: PwrTypography.titleMedium),
                ],
              ),
            ),
            Expanded(
              child: sessions == null
                  ? const SizedBox.shrink()
                  : sessions.isEmpty
                  ? const _Empty()
                  : _MonthList(
                      months: groupByMonth(sessions),
                      onOpenSession: onOpenSession,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthList extends StatelessWidget {
  const _MonthList({required this.months, this.onOpenSession});

  final List<HistoryMonth> months;
  final void Function(String sessionId)? onOpenSession;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.lg,
        PwrSpacing.screenH,
        PwrSpacing.xxl,
      ),
      children: [
        for (final month in months) ...[
          PwrOverline(
            l10n.historyMonth(
              DateFormat.yMMMM(locale).format(month.month),
              month.sessions.length,
            ),
          ),
          const SizedBox(height: PwrSpacing.sm),
          for (final stats in month.sessions) ...[
            _SessionRow(stats: stats, onTap: onOpenSession),
            const SizedBox(height: PwrSpacing.listGap),
          ],
          const SizedBox(height: PwrSpacing.md),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.stats, this.onTap});

  final WorkoutSessionStats stats;
  final void Function(String sessionId)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startedAt = stats.session.startedAt.toLocal();
    final load = formatLoad(stats.volume, locale, compact: false);

    return PwrCard(
      onTap: onTap == null ? null : () => onTap!(stats.session.id),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: PwrSpacing.md,
      ),
      borderRadius: PwrRadius.rowAll,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // A deleted routine leaves the session without a name; it is
                  // still a workout that happened.
                  stats.routineName ?? l10n.historyFreestyle,
                  style: PwrTypography.bodyMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  l10n
                      .historyRowSubtitle(
                        DateFormat.MMMd(locale).format(startedAt),
                        stats.completedSetCount,
                        roundedMinutes(stats.duration ?? Duration.zero),
                      )
                      .toUpperCase(),
                  style: PwrTypography.tag,
                ),
              ],
            ),
          ),
          const SizedBox(width: PwrSpacing.sm),
          Text.rich(
            TextSpan(
              text: load.value,
              children: [
                TextSpan(
                  text: ' ${load.unit}',
                  style: PwrTypography.tag.copyWith(color: PwrColors.textMuted),
                ),
              ],
            ),
            style: PwrTypography.metricXs.copyWith(color: PwrColors.accent),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(PwrSpacing.screenH),
      child: PwrCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.historyEmpty, style: PwrTypography.titleLarge),
            const SizedBox(height: PwrSpacing.xs),
            Text(
              l10n.historyEmptyBody,
              style: PwrTypography.bodyLarge.copyWith(
                color: PwrColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
