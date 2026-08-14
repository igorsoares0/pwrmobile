import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// Everything the summary screen renders, assembled once.
class WorkoutSummary {
  const WorkoutSummary({
    required this.stats,
    required this.exercises,
    this.routineName,
    this.previousVolume,
  });

  final WorkoutSessionStats stats;

  /// Exercises with their sets, ordered as they were performed.
  final List<WorkoutExerciseDetail> exercises;

  /// Null for a freestyle session.
  final String? routineName;

  /// Volume of the previous session on the same routine, if there was one.
  final double? previousVolume;

  /// Change against [previousVolume], as a fraction.
  ///
  /// Null when there is nothing to compare against, and also when the previous
  /// session moved no load at all — dividing by zero would report an infinite
  /// improvement for what was really an empty session.
  double? get volumeDelta {
    final previous = previousVolume;
    if (previous == null || previous <= 0) return null;
    return (stats.volume - previous) / previous;
  }

  /// Exercises that actually had a set checked off.
  List<WorkoutExerciseDetail> get performed =>
      exercises.where((e) => e.completedSets.isNotEmpty).toList();

  bool get isEmpty => performed.isEmpty;

  /// The heaviest completed set of [detail], for the "best today" list.
  ///
  /// Ties on load are broken by reps, so `85×6` beats `85×4`.
  static WorkoutSet? bestSetOf(WorkoutExerciseDetail detail) {
    return detail.completedSets.sorted((a, b) {
      final byWeight = (a.weight ?? 0).compareTo(b.weight ?? 0);
      if (byWeight != 0) return byWeight;
      return (a.reps ?? 0).compareTo(b.reps ?? 0);
    }).lastOrNull;
  }
}

/// Assembles the summary for a finished session.
final workoutSummaryProvider = FutureProvider.family<WorkoutSummary?, String>((
  ref,
  sessionId,
) async {
  final workouts = ref.watch(workoutRepositoryProvider);

  final stats = await workouts.sessionStats(sessionId);
  if (stats == null) return null;

  final exercises = await workouts.sessionExercises(sessionId);

  String? routineName;
  double? previousVolume;

  final routineId = stats.session.routineId;
  if (routineId != null) {
    final routine = await ref
        .watch(routineRepositoryProvider)
        .findById(routineId);
    routineName = routine?.name;

    final previous = await workouts.previousSessionForRoutine(
      routineId,
      before: stats.session.startedAt,
    );
    if (previous != null) {
      previousVolume = (await workouts.sessionStats(previous.id))?.volume;
    }
  }

  return WorkoutSummary(
    stats: stats,
    exercises: exercises,
    routineName: routineName,
    previousVolume: previousVolume,
  );
});
