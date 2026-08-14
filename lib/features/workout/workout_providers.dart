import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// The session currently in progress.
final activeWorkoutProvider = StreamProvider<WorkoutSession?>(
  (ref) => ref.watch(workoutRepositoryProvider).watchActiveSession(),
);

/// Its exercises, each with its sets.
final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExerciseDetail>, String>(
      (ref, sessionId) =>
          ref.watch(workoutRepositoryProvider).watchSessionExercises(sessionId),
    );

/// What the user lifted the last time they trained this exercise.
///
/// Keyed by exercise so switching pages does not refetch what is already
/// resolved, and excluding the session in progress so today's own sets are not
/// offered back as "previous".
final previousPerformanceProvider =
    FutureProvider.family<
      PreviousPerformance?,
      ({String exerciseId, String sessionId})
    >((ref, key) {
      return ref
          .watch(workoutRepositoryProvider)
          .previousPerformance(key.exerciseId, excludeSessionId: key.sessionId);
    });

/// Ticks once a second while a workout screen is mounted.
///
/// Auto-disposed so the timer dies with the screen rather than ticking on in
/// the background — and, in tests, so it does not outlive the widget tree and
/// trip the pending-timer assertion.
final secondTickerProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (count) => count);
});

/// How long the session has been running.
///
/// Recomputed from [WorkoutSession.startedAt] on every tick rather than
/// accumulated, so it stays correct across a process restart — the elapsed
/// time of a workout is a fact about the clock, not about how long the app
/// happened to be open.
final elapsedProvider = Provider.autoDispose.family<Duration, DateTime>((
  ref,
  startedAt,
) {
  ref.watch(secondTickerProvider);
  return DateTime.now().toUtc().difference(startedAt);
});
