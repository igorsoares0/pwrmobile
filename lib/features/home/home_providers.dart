import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/repositories/repositories.dart';

/// The user's routines, with the counts the home cards render.
final routinesProvider = StreamProvider<List<RoutineSummary>>(
  (ref) => ref.watch(routineRepositoryProvider).watchRoutines(),
);

/// This week's totals for the home stat tile.
final weeklyStatsProvider = StreamProvider<WeeklyStats>(
  (ref) => ref.watch(workoutRepositoryProvider).watchWeeklyStats(),
);

// The workout in progress used to be declared here too, for a resume banner on
// this screen. The shell's session bar took that job over — it says the same
// thing from every tab instead of one — so the single declaration now lives
// with the rest of the workout providers.

/// How many exercises the library holds, for the library row subtitle.
final libraryCountProvider = FutureProvider<int>((ref) async {
  final counts = await ref.watch(exerciseRepositoryProvider).countByRegion();
  return counts.values.fold<int>(0, (total, count) => total + count);
});
