import 'package:collection/collection.dart';

import '../app_database.dart';

/// A routine plus the counts the home screen shows without opening it.
class RoutineSummary {
  const RoutineSummary({
    required this.routine,
    required this.exerciseCount,
    required this.plannedSets,
    required this.plannedRestSeconds,
  });

  final Routine routine;
  final int exerciseCount;

  /// Total working sets the routine plans for.
  final int plannedSets;

  /// Total rest the routine plans for, in seconds.
  final int plannedRestSeconds;

  /// Rough session length, for the `~58 min` hint on the routine card.
  ///
  /// Planned rest plus a flat working estimate per set. Deliberately crude —
  /// it is a hint that helps the user pick a routine when they are short on
  /// time, not a prediction, and a more elaborate model would still be wrong.
  Duration get estimatedDuration =>
      Duration(seconds: plannedRestSeconds + plannedSets * _secondsPerSet);

  static const int _secondsPerSet = 30;
}

/// What the user has done in the current week.
class WeeklyStats {
  const WeeklyStats({
    required this.workoutCount,
    required this.completedSetCount,
    required this.volume,
  });

  const WeeklyStats.empty()
    : workoutCount = 0,
      completedSetCount = 0,
      volume = 0;

  final int workoutCount;
  final int completedSetCount;

  /// Load moved this week, in kilograms.
  final double volume;

  bool get isEmpty => workoutCount == 0;
}

/// A routine slot resolved against the exercise library.
class RoutineExerciseDetail {
  const RoutineExerciseDetail({required this.entry, required this.exercise});

  final RoutineExercise entry;
  final Exercise exercise;

  /// Whether this slot is chained to the next one without rest.
  bool get isSuperset => entry.supersetGroup != null;
}

/// An exercise inside a session, with the library row and its sets.
class WorkoutExerciseDetail {
  const WorkoutExerciseDetail({
    required this.entry,
    required this.exercise,
    required this.sets,
  });

  final WorkoutExercise entry;
  final Exercise exercise;

  /// Every set, planned and performed, ordered by set number.
  final List<WorkoutSet> sets;

  List<WorkoutSet> get completedSets =>
      sets.where((set) => set.completed).toList();

  bool get isFinished => sets.isNotEmpty && sets.every((set) => set.completed);

  /// Load moved on this exercise, in kilograms. Warm-ups excluded.
  double get volume => sets.fold(0, (total, set) => total + set.volume);
}

/// What the user did the last time they trained a given exercise.
///
/// Drives the "ANTERIOR 4×8 · 80KG" chip and the pre-filled weight and reps on
/// the workout screen (spec §11).
class PreviousPerformance {
  const PreviousPerformance({required this.session, required this.sets});

  /// The finished session these sets came from.
  final WorkoutSession session;

  /// Completed sets from that session, ordered by set number.
  final List<WorkoutSet> sets;

  /// The heaviest set, used as the headline figure.
  ///
  /// Ties on weight are broken by reps, so `80kg × 8` beats `80kg × 6`.
  WorkoutSet? get bestSet {
    return sets.sorted((a, b) {
      final byWeight = (a.weight ?? 0).compareTo(b.weight ?? 0);
      if (byWeight != 0) return byWeight;
      return (a.reps ?? 0).compareTo(b.reps ?? 0);
    }).lastOrNull;
  }

  /// Working sets only — what "4×8" counts.
  int get workingSetCount =>
      sets.where((set) => set.type.countsTowardsVolume).length;

  double get volume => sets.fold(0, (total, set) => total + set.volume);

  /// The set to seed slot [setNumber] of the next session with, if the user
  /// performed one at that position last time.
  WorkoutSet? suggestionFor(int setNumber) =>
      sets.firstWhereOrNull((set) => set.setNumber == setNumber);
}

/// Totals for one session, for the summary screen.
class WorkoutSessionStats {
  const WorkoutSessionStats({
    required this.session,
    required this.completedSetCount,
    required this.exerciseCount,
    required this.volume,
    this.routineName,
  });

  final WorkoutSession session;

  /// Name of the routine it was started from, or null for a freestyle session
  /// or one whose routine has since been deleted.
  final String? routineName;
  final int completedSetCount;
  final int exerciseCount;

  /// Total load moved, in kilograms. Warm-ups excluded.
  final double volume;

  /// Wall-clock length. Null while the workout is still in progress.
  Duration? get duration {
    final finishedAt = session.finishedAt;
    if (finishedAt == null) return null;
    return finishedAt.difference(session.startedAt);
  }
}

/// Where body weight is now, and where it came from.
///
/// [baseline] is null when there is only one weigh-in, or when every entry in
/// the window is the latest one. That is the honest answer for someone who has
/// stepped on the scale once — a delta of `+0.0` would read as "no progress"
/// rather than "no data yet".
class BodyTrend {
  const BodyTrend({
    required this.latest,
    required this.window,
    this.baseline,
  });

  final BodyMeasurement latest;
  final BodyMeasurement? baseline;

  /// How far back the baseline was looked for.
  final Duration window;

  /// Change in kilograms since [baseline], or null when there is nothing to
  /// compare against.
  double? get deltaKg {
    final from = baseline?.weightKg;
    final to = latest.weightKg;
    if (from == null || to == null) return null;
    return to - from;
  }

  /// Whole weeks between the two entries, for the `IN 12 WEEKS` caption.
  ///
  /// The real span, not the nominal window: a user with two entries a fortnight
  /// apart should read "in 2 weeks", not "in 12".
  int get spanWeeks {
    final from = baseline?.measuredAt;
    if (from == null) return 0;
    return latest.measuredAt.difference(from).inDays ~/ 7;
  }
}

/// One completed set flattened with everything it belongs to.
///
/// The shape a spreadsheet wants: no nesting, every row self-describing. Built
/// only for export, which is why it carries the routine name as a string —
/// the file outlives the database it came from, and a session whose routine is
/// later deleted still has to say what it was.
class ExportedSet {
  const ExportedSet({
    required this.session,
    required this.exercise,
    required this.set,
    this.routineName,
  });

  final WorkoutSession session;
  final Exercise exercise;
  final WorkoutSet set;
  final String? routineName;
}

extension WorkoutSetVolume on WorkoutSet {
  /// Load moved by this set, in kilograms.
  ///
  /// Zero unless the set was actually completed and counts towards volume —
  /// a planned set the user never checked off did not happen, and a warm-up
  /// is not training load.
  double get volume {
    if (!completed || !type.countsTowardsVolume) return 0;
    final weight = this.weight;
    final reps = this.reps;
    if (weight == null || reps == null) return 0;
    return weight * reps;
  }
}
