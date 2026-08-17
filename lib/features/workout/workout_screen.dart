import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import 'rest_pill.dart';
import 'rest_timer.dart';
import 'set_row.dart';
import 'workout_blocks.dart';
import 'workout_providers.dart';

/// The workout in progress.
///
/// One vertical scroll holding every exercise, with a rail of shortcuts across
/// the top. It used to be a horizontal `PageView`, one exercise per page, which
/// hid the shape of the session behind a swipe and made a superset — two
/// movements alternated set by set — a matter of paging back and forth six
/// times. Here both halves of a pair are simply on screen together.
///
/// The spec's success criterion (§23) is this screen working with no network at
/// all — nothing here touches anything but SQLite.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.sessionId,
    this.onFinished,
    this.onDiscarded,
    this.onPickExercise,
  });

  final String sessionId;
  final VoidCallback? onFinished;

  /// Called after the session is thrown away.
  ///
  /// Separate from [onFinished] because the destinations differ: a finished
  /// workout has a summary worth reading, a discarded one has nothing to show.
  final VoidCallback? onDiscarded;

  /// Opens the library as a picker and resolves to the chosen exercise.
  ///
  /// A session started from the centre button has no routine behind it, so
  /// without this it would be a screen with nothing to log.
  final Future<Exercise?> Function()? onPickExercise;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// One key per exercise, so the rail can scroll its block into view.
  ///
  /// Kept in a map rather than rebuilt per frame: a `GlobalKey` recreated on
  /// every build loses the element it was pointing at, which is the one thing
  /// it exists to remember.
  final _anchors = <String, GlobalKey>{};

  GlobalKey _anchorFor(String entryId) =>
      _anchors.putIfAbsent(entryId, GlobalKey.new);

  Future<void> _jumpTo(String entryId) async {
    final anchor = _anchors[entryId]?.currentContext;
    if (anchor == null) return;

    await Scrollable.ensureVisible(
      anchor,
      duration: PwrDuration.normal,
      curve: Curves.easeOutCubic,
      // A hair below the top edge, so the exercise name does not sit flush
      // against the rail above it.
      alignment: 0.02,
    );
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

    final blocks = blocksOf(exercises);
    final allSets = [for (final e in exercises) ...e.sets];
    final done = allSets.where((s) => s.completed).length;
    final active = _activeEntryId(exercises);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SessionHeader(
              startedAt: session.startedAt,
              done: done,
              total: allSets.length,
              onDiscard: () => _confirmDiscard(done),
            ),
            if (blocks.isNotEmpty)
              _ExerciseRail(
                blocks: blocks,
                activeEntryId: active,
                onJump: _jumpTo,
              ),
            Expanded(
              // The rest pill floats over the list rather than sitting in this
              // column. In the column its height came out of the page above,
              // which shifted the content at the exact moment a thumb came off
              // the checkmark.
              child: Stack(
                children: [
                  Positioned.fill(
                    child: exercises.isEmpty
                        ? _NoExercises(
                            sessionId: widget.sessionId,
                            onPickExercise: widget.onPickExercise,
                          )
                        : _BlockList(
                            sessionId: widget.sessionId,
                            blocks: blocks,
                            anchorFor: _anchorFor,
                            onPickExercise: widget.onPickExercise,
                          ),
                  ),
                  const Positioned(
                    left: PwrSpacing.screenH,
                    right: PwrSpacing.screenH,
                    bottom: PwrSpacing.sm,
                    child: RestPill(),
                  ),
                ],
              ),
            ),
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

  /// Where the user is in the workout: the first exercise still holding an
  /// unchecked set.
  ///
  /// Deliberately not "whichever block is scrolled into view". Scrolling ahead
  /// to see what is coming should not move the marker for where you actually
  /// are, and reading the scroll position would make the rail flicker under a
  /// thumb that is only browsing.
  String? _activeEntryId(List<WorkoutExerciseDetail> exercises) {
    for (final detail in exercises) {
      if (detail.sets.any((set) => !set.completed)) return detail.entry.id;
    }
    return exercises.isEmpty ? null : exercises.last.entry.id;
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

  /// Throws the session away.
  ///
  /// A dialog rather than the undo snackbar the rest of the app is moving
  /// towards: undo needs somewhere to live, and this action ends by leaving
  /// the screen the user would have to be on to press it. The dialog says how
  /// many sets are about to go, because "descartar treino" on its own does not
  /// distinguish a mis-tap thirty seconds in from an hour of work.
  Future<void> _confirmDiscard(int done) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutDiscard),
        content: Text(l10n.workoutDiscardConfirm(done)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.workoutDiscardAction,
              style: const TextStyle(color: PwrColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ref.read(restTimerProvider.notifier).skip();
    await ref.read(workoutRepositoryProvider).discard(widget.sessionId);
    widget.onDiscarded?.call();
  }
}

class _SessionHeader extends ConsumerWidget {
  const _SessionHeader({
    required this.startedAt,
    required this.done,
    required this.total,
    required this.onDiscard,
  });

  final DateTime startedAt;
  final int done;
  final int total;
  final VoidCallback onDiscard;

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
              // Sets, not "exercise 3 of 6": the rail below already shows where
              // in the list you are, and the bar underneath this line measures
              // sets. Two different counters describing the same progress bar
              // is one too many.
              Expanded(child: PwrOverline(l10n.workoutProgressSets(done, total))),
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
              // Up here, not next to "Finalizar treino". Discarding is rare and
              // destructive, finishing is what every session ends with, and
              // putting them a thumb's width apart at the bottom of the screen
              // is how a mis-tap throws away an hour of work. Same icon and
              // same corner as deleting a routine in the builder.
              const SizedBox(width: PwrSpacing.xs),
              IconButton(
                onPressed: onDiscard,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.workoutDiscard,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ],
          ),
          const SizedBox(height: PwrSpacing.md),
          PwrProgressBar(value: total == 0 ? 0 : done / total),
        ],
      ),
    );
  }
}

/// The shortcut rail: one pill per exercise, with a dot per set.
///
/// It is the overview the `PageView` never gave. Tapping jumps; the dots say
/// how far each exercise got without opening it.
class _ExerciseRail extends ConsumerStatefulWidget {
  const _ExerciseRail({
    required this.blocks,
    required this.onJump,
    this.activeEntryId,
  });

  final List<WorkoutBlock> blocks;
  final String? activeEntryId;
  final Future<void> Function(String entryId) onJump;

  @override
  ConsumerState<_ExerciseRail> createState() => _ExerciseRailState();
}

class _ExerciseRailState extends ConsumerState<_ExerciseRail> {
  final _items = <String, GlobalKey>{};

  GlobalKey _keyFor(String entryId) =>
      _items.putIfAbsent(entryId, GlobalKey.new);

  @override
  void didUpdateWidget(_ExerciseRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeEntryId != oldWidget.activeEntryId) _followActive();
  }

  /// Keeps the exercise you are on inside the rail.
  ///
  /// Without this the rail is only useful for the first three exercises: by
  /// the time you are on the fifth, its shortcut has scrolled off the right
  /// edge and reaching it means scrolling the shortcuts to reach the shortcut.
  void _followActive() {
    final id = widget.activeEntryId;
    if (id == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final anchor = _items[id]?.currentContext;
      if (anchor == null || !mounted) return;

      unawaited(
        Scrollable.ensureVisible(
          anchor,
          duration: PwrDuration.normal,
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider);
    final language = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: PwrSpacing.md),
      child: SizedBox(
        height: 58,
        // Not a lazy list, for the same reason the blocks are not: an item
        // that has scrolled off the right edge has no context, and a shortcut
        // that only works while already visible is not a shortcut.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: PwrSpacing.screenH),
          child: Row(
            children: [
              for (final block in widget.blocks)
                for (final (index, detail) in block.members.indexed) ...[
                  _RailItem(
                    key: _keyFor(detail.entry.id),
                    label: detail.exercise.displayName(catalog, language),
                    marker: block.labelFor(index),
                    sets: detail.sets,
                    active: detail.entry.id == widget.activeEntryId,
                    onTap: () => widget.onJump(detail.entry.id),
                  ),
                  const SizedBox(width: PwrSpacing.xs),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.label,
    required this.sets,
    required this.active,
    required this.onTap,
    this.marker,
  });

  final String label;

  /// `A1`, `A2`… when the exercise is half of a superset.
  final String? marker;

  final List<WorkoutSet> sets;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PwrColors.surfaceAccent : PwrColors.surface,
      borderRadius: PwrRadius.rowAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 76, maxWidth: 132),
          padding: const EdgeInsets.symmetric(
            horizontal: PwrSpacing.sm,
            vertical: PwrSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: PwrRadius.rowAll,
            border: Border.all(
              color: active ? PwrColors.borderAccent : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (marker != null) ...[
                    Text(
                      marker!,
                      style: PwrTypography.tag.copyWith(
                        color: PwrColors.accent,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: PwrTypography.tag.copyWith(
                        color: active
                            ? PwrColors.textPrimary
                            : PwrColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _SetDots(sets: sets),
            ],
          ),
        ),
      ),
    );
  }
}

/// One dot per set, filled once it is checked off.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.sets});

  final List<WorkoutSet> sets;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final set in sets)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: AnimatedContainer(
              duration: PwrDuration.fast,
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: set.completed
                    ? PwrColors.accent
                    : PwrColors.surfaceRaised,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlockList extends ConsumerWidget {
  const _BlockList({
    required this.sessionId,
    required this.blocks,
    required this.anchorFor,
    this.onPickExercise,
  });

  final String sessionId;
  final List<WorkoutBlock> blocks;
  final GlobalKey Function(String entryId) anchorFor;
  final Future<Exercise?> Function()? onPickExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Every block is built, not just the ones on screen.
    //
    // A lazy `ListView` never builds what is below the fold, so the anchor the
    // rail scrolls to does not exist yet — and the exercises worth jumping to
    // are precisely the ones off screen. It also disposes a row's controllers
    // when it scrolls away, which is not something the screen you type into
    // should do. A workout is a handful of exercises, not a feed; building all
    // of it costs nothing and makes both problems go away.
    return SingleChildScrollView(
      // The bottom inset is reserved whether or not a rest is running. Growing
      // it only while the pill is up would reintroduce exactly the jump the
      // pill was moved out of the column to avoid.
      padding: const EdgeInsets.fromLTRB(
        PwrSpacing.screenH,
        PwrSpacing.md,
        PwrSpacing.screenH,
        RestPill.reservedHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final block in blocks) ...[
            _Block(
              sessionId: sessionId,
              block: block,
              anchorFor: anchorFor,
            ),
            const SizedBox(height: PwrSpacing.xl),
          ],
          if (onPickExercise != null)
            _AddExerciseButton(
              sessionId: sessionId,
              onPickExercise: onPickExercise!,
            ),
        ],
      ),
    );
  }
}

/// One exercise, or a superset drawn as the single unit it is performed as.
class _Block extends StatelessWidget {
  const _Block({
    required this.sessionId,
    required this.block,
    required this.anchorFor,
  });

  final String sessionId;
  final WorkoutBlock block;
  final GlobalKey Function(String entryId) anchorFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final members = <Widget>[
      for (final (index, detail) in block.members.indexed) ...[
        if (index > 0) const SizedBox(height: PwrSpacing.lg),
        _Exercise(
          key: anchorFor(detail.entry.id),
          sessionId: sessionId,
          detail: detail,
          marker: block.labelFor(index),
          // In a superset the rest belongs to the end of the pair, not between
          // its halves — going straight into the next movement is the whole
          // point. Only the last member starts the countdown.
          startsRest: index == block.members.length - 1,
        ),
      ],
    ];

    if (!block.isSuperset) return Column(children: members);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PwrTag(
          l10n.workoutSupersetOf(block.letter!).toUpperCase(),
          tone: PwrTagTone.accent,
        ),
        const SizedBox(height: PwrSpacing.sm),
        // The rail down the left is what says "these are one thing". Without
        // it, two exercises with a tag above them read as two exercises.
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: PwrColors.accentStrong, width: 3),
            ),
          ),
          padding: const EdgeInsets.only(left: PwrSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: members,
          ),
        ),
      ],
    );
  }
}

class _Exercise extends ConsumerWidget {
  const _Exercise({
    super.key,
    required this.sessionId,
    required this.detail,
    required this.startsRest,
    this.marker,
  });

  final String sessionId;
  final WorkoutExerciseDetail detail;

  /// `A1`, `A2`… when this is part of a superset.
  final String? marker;

  /// Whether checking a set off here begins the rest countdown.
  final bool startsRest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider);
    final language = Localizations.localeOf(context).languageCode;
    final name = detail.exercise.displayName(catalog, language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (marker != null) ...[
              Text(
                marker!,
                style: PwrTypography.metricXs.copyWith(
                  color: PwrColors.accent,
                ),
              ),
              const SizedBox(width: PwrSpacing.xs),
            ],
            Expanded(child: Text(name, style: PwrTypography.titleLarge)),
          ],
        ),
        const SizedBox(height: PwrSpacing.xs),
        _PreviousChip(sessionId: sessionId, detail: detail),
        const SetRowHeader(),
        for (final set in detail.sets)
          SetRow(
            key: ValueKey(set.id),
            set: set,
            restSeconds: detail.entry.restSeconds,
            onCompleted: startsRest
                ? (seconds) => ref.read(restTimerProvider.notifier).start(seconds)
                : (_) {},
          ),
        const SizedBox(height: PwrSpacing.xs),
        PwrButton.ghost(
          label: l10n.workoutAddSet,
          onPressed: () =>
              ref.read(workoutRepositoryProvider).addSet(detail.entry.id),
        ),
      ],
    );
  }
}

/// What the user lifted here last time.
class _PreviousChip extends ConsumerWidget {
  const _PreviousChip({required this.sessionId, required this.detail});

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
    final unit = ref.watch(weightUnitProvider);

    return Align(
      alignment: Alignment.centerLeft,
      child: PwrTag(
        best == null
            ? l10n.workoutNoPrevious.toUpperCase()
            : l10n
                  .workoutPrevious(
                    previous!.workingSetCount,
                    best.reps ?? 0,
                    formatSetLoad(best.weight ?? 0, locale, unit: unit),
                    unit.symbol,
                  )
                  .toUpperCase(),
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

    return PwrListRow.placeholder(
      title: l10n.workoutAddExercise,
      leading: const Icon(Icons.add, size: 16, color: PwrColors.textMuted),
      onTap: () async {
        final exercise = await onPickExercise();
        if (exercise == null) return;
        await ref
            .read(workoutRepositoryProvider)
            .addExercise(
              sessionId: sessionId,
              exerciseId: exercise.id,
              restSeconds: ref.read(preferencesProvider).defaultRestSeconds,
            );
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
