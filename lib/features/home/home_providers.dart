import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// The user's routines, with the counts the home cards render.
final routinesProvider = StreamProvider<List<RoutineSummary>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutines(),
);

/// This week's totals for the home stat tile.
final weeklyStatsProvider = StreamProvider<WeeklyStats>(
  (ref) => ref.watch(workoutRepositoryProvider).watchWeeklyStats(),
);

/// The workout in progress, if any.
///
/// Home surfaces it as a resume banner: a session left open means the user
/// walked away mid-workout, and burying that behind navigation would make the
/// offline crash-recovery invisible.
final activeSessionProvider = StreamProvider<WorkoutSession?>(
  (ref) => ref.watch(workoutRepositoryProvider).watchActiveSession(),
);

/// How many exercises the library holds, for the library row subtitle.
final libraryCountProvider = FutureProvider<int>((ref) async {
  final counts = await ref.watch(exerciseRepositoryProvider).countByRegion();
  return counts.values.fold<int>(0, (total, count) => total + count);
});
