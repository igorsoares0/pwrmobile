import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/database/repositories/repositories.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import '../subscription/entitlement.dart';
import 'home_providers.dart';

/// The landing screen: what you did this week, and the routine you are about
/// to run.
///
/// Everything here is one tap from starting a workout, because that is the
/// only thing the user opened the app to do.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onStartRoutine,
    this.onOpenLibrary,
    this.onCreateRoutine,
    this.onEditRoutine,
    this.onResumeWorkout,
    this.onOpenHistory,
  });

  final void Function(String routineId)? onStartRoutine;
  final VoidCallback? onOpenLibrary;
  final VoidCallback? onCreateRoutine;
  final void Function(String routineId)? onEditRoutine;
  final void Function(String sessionId)? onResumeWorkout;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PwrSpacing.screenH,
            PwrSpacing.screenTop,
            PwrSpacing.screenH,
            PwrSpacing.xxl,
          ),
          children: [
            const _Header(),
            const SizedBox(height: PwrSpacing.xl),
            const _Greeting(),
            const SizedBox(height: PwrSpacing.lg),
            _WeeklyStatsCard(onTap: onOpenHistory),
            _ResumeBanner(onResume: onResumeWorkout),
            const SizedBox(height: PwrSpacing.xl),

            // The routine list drives the whole screen, so its three states —
            // loading, empty, populated — are spelled out rather than collapsed
            // into a spinner. A returning user must never see a blank frame
            // where their routines belong.
            routines.when(
              loading: () => const _RoutinesLoading(),
              error: (error, _) => _RoutinesError(error: error),
              data: (data) => data.isEmpty
                  ? _EmptyRoutines(onCreateRoutine: onCreateRoutine)
                  : _RoutineList(
                      routines: data,
                      onStartRoutine: onStartRoutine,
                      onCreateRoutine: onCreateRoutine,
                      onEditRoutine: onEditRoutine,
                    ),
            ),

            const SizedBox(height: PwrSpacing.sm),
            _LibraryRow(onTap: onOpenLibrary, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Row(children: [Text('PWR', style: PwrTypography.wordmark)]);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrOverline(
          l10n.homeWeekLabel(weekdayName(now, locale), isoWeekNumber(now)),
          wide: true,
        ),
        const SizedBox(height: PwrSpacing.sm),
        Text(l10n.homeGreeting, style: PwrTypography.displayMedium),
      ],
    );
  }
}

class _WeeklyStatsCard extends ConsumerWidget {
  const _WeeklyStatsCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // An unresolved stream shows zeroes rather than a spinner: the tile keeps
    // its size, so the routines below never jump once the numbers land.
    final stats = ref
        .watch(weeklyStatsProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const WeeklyStats.empty(),
        );

    final load = formatLoad(
      stats.volume,
      locale,
      unit: ref.watch(weightUnitProvider),
    );

    // The week's numbers open the sessions behind them. A dedicated history
    // tab arrives with the bottom navigation; until then this is the way in.
    return PwrCard(
      onTap: onTap,
      child: PwrStatRow(
        stats: [
          PwrStat(
            value: '${stats.workoutCount}',
            caption: l10n.homeStatWorkouts,
            valueColor: PwrColors.accent,
          ),
          PwrStat(
            value: load.value,
            unit: load.unit,
            caption: l10n.homeStatVolume,
          ),
          PwrStat(
            value: '${stats.completedSetCount}',
            caption: l10n.homeStatSets,
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends ConsumerWidget {
  const _ResumeBanner({this.onResume});

  final void Function(String sessionId)? onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider).value;
    if (session == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: PwrSpacing.cardGap),
      child: PwrCard(
        onTap: onResume == null ? null : () => onResume!(session.id),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeResumeWorkout, style: PwrTypography.bodyMedium),
                  const SizedBox(height: 7),
                  Text(
                    l10n.homeResumeAction.toUpperCase(),
                    style: PwrTypography.tag.copyWith(color: PwrColors.accent),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: PwrColors.accent),
          ],
        ),
      ),
    );
  }
}

class _RoutineList extends ConsumerWidget {
  const _RoutineList({
    required this.routines,
    this.onStartRoutine,
    this.onCreateRoutine,
    this.onEditRoutine,
  });

  final List<RoutineSummary> routines;
  final void Function(String routineId)? onStartRoutine;
  final VoidCallback? onCreateRoutine;
  final void Function(String routineId)? onEditRoutine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entitlement = ref.watch(entitlementProvider);
    final limit = entitlement.routineLimit;
    final canCreate = entitlement.canCreateRoutine(routines.length);

    final first = routines.first;
    final rest = routines.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrOverline(
          l10n.homeRoutinesTitle,
          trailing: Text(
            limit == null
                ? l10n.homeRoutinesUnlimited(routines.length)
                : l10n.homeRoutinesCounter(routines.length, limit),
            style: PwrTypography.tag,
          ),
        ),
        const SizedBox(height: PwrSpacing.sm),

        // The first routine gets the accent card and the play button: it is
        // the one the user is most likely to run, and it should be reachable
        // without reading the list.
        _PrimaryRoutineCard(
          summary: first,
          onTap: () => onStartRoutine?.call(first.routine.id),
        ),

        for (final summary in rest) ...[
          const SizedBox(height: PwrSpacing.listGap),
          _SecondaryRoutineRow(
            summary: summary,
            onTap: () => onStartRoutine?.call(summary.routine.id),
            onEdit: () => onEditRoutine?.call(summary.routine.id),
          ),
        ],

        const SizedBox(height: PwrSpacing.listGap),
        PwrListRow.placeholder(
          title: l10n.homeNewRoutine,
          subtitle: canCreate ? null : l10n.homeNewRoutineLocked.toUpperCase(),
          leading: Icon(
            canCreate ? Icons.add : Icons.lock_outline,
            size: 16,
            color: PwrColors.textMuted,
          ),
          // At the limit the row stays tappable but does nothing yet; the
          // paywall it should open arrives in phase 4.
          onTap: canCreate ? onCreateRoutine : null,
        ),
      ],
    );
  }
}

class _PrimaryRoutineCard extends StatelessWidget {
  const _PrimaryRoutineCard({required this.summary, this.onTap});

  final RoutineSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final routine = summary.routine;

    return PwrCard.accent(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: PwrTypography.titleLarge.copyWith(
                    color: PwrColors.onAccent,
                  ),
                ),
                if (routine.focus case final focus?) ...[
                  const SizedBox(height: 2),
                  Text(
                    focus,
                    style: PwrTypography.titleLarge.copyWith(
                      color: PwrColors.onAccent,
                    ),
                  ),
                ],
                const SizedBox(height: PwrSpacing.sm),
                Text(
                  l10n
                      .homeRoutineSubtitle(
                        summary.exerciseCount,
                        roundedMinutes(summary.estimatedDuration),
                      )
                      .toUpperCase(),
                  style: PwrTypography.tag.copyWith(
                    color: PwrColors.onAccent.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PwrSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: PwrColors.textPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: PwrColors.accentStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryRoutineRow extends StatelessWidget {
  const _SecondaryRoutineRow({required this.summary, this.onTap, this.onEdit});

  final RoutineSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PwrListRow(
      title: summary.routine.name,
      subtitle: [
        ?summary.routine.focus,
        l10n.homeRoutineSubtitle(
          summary.exerciseCount,
          roundedMinutes(summary.estimatedDuration),
        ),
      ].join(' · ').toUpperCase(),
      // Tapping the row starts the workout; editing lives behind the pencil,
      // because starting is what the user came to do.
      trailing: IconButton(
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
      onTap: onTap,
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({this.onCreateRoutine});

  final VoidCallback? onCreateRoutine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrOverline(l10n.homeRoutinesTitle),
        const SizedBox(height: PwrSpacing.sm),
        PwrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeEmptyTitle, style: PwrTypography.titleLarge),
              const SizedBox(height: PwrSpacing.xs),
              Text(
                l10n.homeEmptyBody,
                style: PwrTypography.bodyLarge.copyWith(
                  color: PwrColors.textMuted,
                ),
              ),
              const SizedBox(height: PwrSpacing.md),
              PwrButton(
                label: l10n.homeEmptyAction,
                onPressed: onCreateRoutine,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutinesLoading extends StatelessWidget {
  const _RoutinesLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Placeholder blocks rather than a spinner, so the screen does not resize
    // under the user's thumb when the routines arrive.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrOverline(l10n.homeRoutinesTitle),
        const SizedBox(height: PwrSpacing.sm),
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: PwrSpacing.listGap),
          const SizedBox(height: 64, child: PwrCard(child: SizedBox.shrink())),
        ],
      ],
    );
  }
}

class _RoutinesError extends StatelessWidget {
  const _RoutinesError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return PwrCard(
      child: Text(
        '$error',
        style: PwrTypography.bodySmall.copyWith(color: PwrColors.danger),
      ),
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.l10n, this.onTap});

  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(libraryCountProvider).value;

    return PwrListRow(
      title: l10n.homeLibrary,
      subtitle: count == null
          ? null
          : l10n.homeLibraryCount(count).toUpperCase(),
      onTap: onTap,
    );
  }
}
