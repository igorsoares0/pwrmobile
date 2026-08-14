import 'package:drift/drift.dart';

import 'exercises.dart';
import 'synced_table.dart';
import 'workout_sessions.dart';

/// An exercise as performed inside a session.
///
/// Copied from [RoutineExercises] when the workout starts, then free to
/// diverge — the user can reorder, skip, or add movements mid-workout without
/// touching the routine they came from.
@TableIndex(name: 'idx_workout_exercises_session', columns: {#sessionId})
@TableIndex(name: 'idx_workout_exercises_exercise', columns: {#exerciseId})
class WorkoutExercises extends Table with SyncedTable {
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();

  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// Order within the session.
  IntColumn get position => integer()();

  /// Rest seeded from the routine, adjustable during the workout.
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  /// Superset marker, carrying the same semantics as on the routine.
  IntColumn get supersetGroup => integer().nullable()();

  TextColumn get notes => text().nullable()();
}
