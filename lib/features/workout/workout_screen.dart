import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import 'rest_timer.dart';
import 'set_row.dart';
import 'workout_providers.dart';

/// The workout in progress.
///
/// One exercise at a time, swipeable, with its sets already filled in from the
/// last session. The spec's success criterion (§23) is this screen working
/// with no network at all — nothing here touches anything but SQLite.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.sessionId,
    this.onFinished,
    this.onPickExercise,
  });

  final String sessionId;
  final VoidCallback? onFinished;

  /// Opens the library as a picker and resolves to the chosen exercise.
  ///
  /// A session started from the centre button has no routine behind it, so
  /// without this it would be a screen with nothing to log.
  final Future<Exercise?> Function()? onPickExercise;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _pages = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(activeWorkoutProvider).value;
    final exercises =
        ref.watch(workoutExercisesProvider(widget.sessionId)).value ??
        const <WorkoutExerciseDetail>[];

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.workoutNoSession, style: PwrTypography.bodyLarge),
        ),
      );
    }

    final allSets = [for (final e in exercises) ...e.sets];
    final done = allSets.where((s) => s.completed).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SessionHeader(
              startedAt: session.startedAt,
              current: exercises.isEmpty ? 0 : _current + 1,
              total: exercises.length,
              progress: allSets.isEmpty ? 0 : done / allSets.length,
            ),
            Expanded(
              child: exercises.isEmpty
                  ? _NoExercises(
                      sessionId: widget.sessionId,
                      onPickExercise: widget.onPickExercise,
                    )
                  : PageView.builder(
                      controller: _pages,
                      itemCount: exercises.length,
                      onPageChanged: (index) =>
                          setState(() => _current = index),
                      itemBuilder: (context, index) => _ExercisePage(
                        sessionId: widget.sessionId,
                        detail: exercises[index],
                        next: index + 1 < exercises.length
                            ? exercises[index + 1]
                            : null,
                        onPickExercise: widget.onPickExercise,
                      ),
                    ),
            ),
            const _RestCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PwrSpacing.screenH,
                PwrSpacing.cardGap,
                PwrSpacing.screenH,
                PwrSpacing.md,
              ),
              child: PwrButton.secondary(
                label: l10n.workoutFinish,
                onPressed: () => _confirmFinish(done, allSets.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFinish(int done, int planned) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutFinish),
        content: Text(l10n.workoutFinishConfirm(done, planned)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.workoutFinishAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Dismiss any running rest before leaving, so its ticker does not outlive
    // the screen.
    ref.read(restTimerProvider.notifier).skip();
    await ref.read(workoutRepositoryProvider).finish(widget.sessionId);
    widget.onFinished?.call();
  }
}

class _SessionHeader extends ConsumerWidget {
  const _SessionHeader({
    required this.startedAt,
    required this.current,
    required this.total,
    required this.progress,
  });

  final DateTime startedAt;
  final int current;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final elapsed = ref.watch(elapsedProvider(startedAt));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.screenTop,
        PwrSpacing.screenH,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PwrOverline(l10n.workoutInProgress(current, total)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatClock(elapsed),
                    style: PwrTypography.metricMd.copyWith(
                      color: PwrColors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.workoutTotal.toUpperCase(),
                    style: PwrTypography.metricCaption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: PwrSpacing.md),
          PwrProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _ExercisePage extends ConsumerWidget {
  const _ExercisePage({
    required this.sessionId,
    required this.detail,
    this.next,
    this.onPickExercise,
  });

  final String sessionId;
  final WorkoutExerciseDetail detail;
  final WorkoutExerciseDetail? next;
  final Future<Exercise?> Function()? onPickExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider);
    final language = Localizations.localeOf(context).languageCode;
    final name = detail.exercise.displayName(catalog, language);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.md,
        PwrSpacing.screenH,
        PwrSpacing.md,
      ),
      children: [
        Text(name, style: PwrTypography.headline),
        const SizedBox(height: PwrSpacing.sm),
        _Chips(sessionId: sessionId, detail: detail),
        const SetRowHeader(),
        for (final set in detail.sets)
          SetRow(
            key: ValueKey(set.id),
            set: set,
            restSeconds: detail.entry.restSeconds,
            onCompleted: (seconds) =>
                ref.read(restTimerProvider.notifier).start(seconds),
          ),
        const SizedBox(height: PwrSpacing.xs),
        PwrButton.ghost(
          label: l10n.workoutAddSet,
          onPressed: () =>
              ref.read(workoutRepositoryProvider).addSet(detail.entry.id),
        ),
        const SizedBox(height: PwrSpacing.md),
        Text(
          next == null
              ? l10n.workoutLastExercise
              : l10n.workoutNext(next!.exercise.displayName(catalog, language)),
          style: PwrTypography.caption,
        ),
      ],
    );
  }
}

class _Chips extends ConsumerWidget {
  const _Chips({required this.sessionId, required this.detail});

  final String sessionId;
  final WorkoutExerciseDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final previous = ref
        .watch(
          previousPerformanceProvider((
            exerciseId: detail.entry.exerciseId,
            sessionId: sessionId,
          )),
        )
        .value;

    final best = previous?.bestSet;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Wrap(
      spacing: PwrSpacing.xs,
      runSpacing: PwrSpacing.xs,
      children: [
        if (detail.entry.supersetGroup != null)
          PwrTag(l10n.workoutSuperset.toUpperCase(), tone: PwrTagTone.accent),
        PwrTag(
          best == null
              ? l10n.workoutNoPrevious.toUpperCase()
              : l10n
                    .workoutPrevious(
                      previous!.workingSetCount,
                      best.reps ?? 0,
                      formatLoad(best.weight ?? 0, locale).value,
                    )
                    .toUpperCase(),
        ),
      ],
    );
  }
}

class _RestCard extends ConsumerWidget {
  const _RestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rest = ref.watch(restTimerProvider);
    final notifier = ref.read(restTimerProvider.notifier);

    if (!rest.isActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PwrSpacing.screenH),
      child: PwrCard(
        borderRadius: PwrRadius.cardLargeAll,
        padding: const EdgeInsets.symmetric(
          horizontal: PwrSpacing.lg,
          vertical: 18,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PwrOverline(l10n.workoutRest),
                  const SizedBox(height: PwrSpacing.xs),
                  Text(
                    formatClock(rest.remaining),
                    style: PwrTypography.metricLg.copyWith(
                      color: rest.isFinished
                          ? PwrColors.textPrimary
                          : PwrColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            // Skip is always available, not just once the countdown expires.
            // Resting is a suggestion; the user who wants to go straight into
            // the next set must not have to wait the timer out or hunt for a
            // way to dismiss it.
            Wrap(
              spacing: PwrSpacing.xs,
              runSpacing: PwrSpacing.xs,
              alignment: WrapAlignment.end,
              children: [
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
                if (!rest.isFinished)
                  PwrButton(
                    label: rest.running
                        ? l10n.workoutRestPause
                        : l10n.workoutRestResume,
                    size: PwrButtonSize.compact,
                    expand: false,
                    onPressed: rest.running ? notifier.pause : notifier.resume,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseButton extends ConsumerWidget {
  const _AddExerciseButton({
    required this.sessionId,
    required this.onPickExercise,
  });

  final String sessionId;
  final Future<Exercise?> Function() onPickExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PwrButton.ghost(
      label: l10n.workoutAddExercise,
      onPressed: () async {
        final exercise = await onPickExercise();
        if (exercise == null) return;
        await ref
            .read(workoutRepositoryProvider)
            .addExercise(sessionId: sessionId, exerciseId: exercise.id);
      },
    );
  }
}

class _NoExercises extends ConsumerWidget {
  const _NoExercises({required this.sessionId, this.onPickExercise});

  final String sessionId;
  final Future<Exercise?> Function()? onPickExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(PwrSpacing.screenH),
      child: PwrCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workoutEmpty, style: PwrTypography.titleLarge),
            const SizedBox(height: PwrSpacing.xs),
            Text(
              l10n.workoutEmptyBody,
              style: PwrTypography.bodyLarge.copyWith(
                color: PwrColors.textMuted,
              ),
            ),
            if (onPickExercise != null) ...[
              const SizedBox(height: PwrSpacing.md),
              _AddExerciseButton(
                sessionId: sessionId,
                onPickExercise: onPickExercise!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
