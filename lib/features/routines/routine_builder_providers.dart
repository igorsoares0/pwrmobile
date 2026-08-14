import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// The routine being edited.
final routineProvider = StreamProvider.family<Routine?, String>(
  (ref, routineId) => ref.watch(routineRepositoryProvider).watchById(routineId),
);

/// Its exercise slots, in order, resolved against the library.
final routineSlotsProvider =
    StreamProvider.family<List<RoutineExerciseDetail>, String>(
      (ref, routineId) =>
          ref.watch(routineRepositoryProvider).watchExercises(routineId),
    );

/// How many routines exist, for the Free-plan check before creating another.
final routineCountProvider = FutureProvider<int>(
  (ref) => ref.watch(routineRepositoryProvider).countRoutines(),
);

/// Whether slot `i` is performed back to back with slot `i + 1`.
///
/// Derived rather than stored: two adjacent slots are chained when they share
/// a non-null superset group. Keeping this a projection of the group ids means
/// the UI cannot drift out of step with what the database actually holds.
List<bool> chainFlagsOf(List<RoutineExerciseDetail> slots) {
  return [
    for (var i = 0; i < slots.length; i++)
      i < slots.length - 1 &&
          slots[i].entry.supersetGroup != null &&
          slots[i].entry.supersetGroup == slots[i + 1].entry.supersetGroup,
  ];
}
