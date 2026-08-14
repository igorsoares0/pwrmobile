import 'package:drift/drift.dart';

import 'exercises.dart';
import 'routines.dart';
import 'synced_table.dart';

/// An exercise slot inside a routine template.
///
/// This is the plan, not the record: it says "four sets of bench press with 90
/// seconds of rest", while [WorkoutSets] holds what was actually lifted.
@TableIndex(name: 'idx_routine_exercises_routine', columns: {#routineId})
@TableIndex(name: 'idx_routine_exercises_exercise', columns: {#exerciseId})
class RoutineExercises extends Table with SyncedTable {
  TextColumn get routineId => text().references(Routines, #id)();

  TextColumn get exerciseId => text().references(Exercises, #id)();

  /// Order within the routine. Rewritten when the user drags to reorder.
  IntColumn get position => integer()();

  /// How many working sets the plan calls for.
  IntColumn get targetSets => integer().withDefault(const Constant(3))();

  /// Target repetitions per set. Null when the user tracks the movement by
  /// load or time rather than a rep target.
  IntColumn get targetReps => integer().nullable()();

  /// Rest between sets, seeded into the rest timer during the workout.
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();

  /// Superset marker.
  ///
  /// Consecutive rows sharing a non-null value are performed back to back
  /// without rest. Null means the exercise stands alone. A group id rather
  /// than a "chains with next" flag, because deleting the middle exercise of a
  /// three-movement superset must not silently re-pair its neighbours.
  IntColumn get supersetGroup => integer().nullable()();

  TextColumn get notes => text().nullable()();
}
