import 'package:drift/drift.dart';

import '../enums.dart';
import 'synced_table.dart';
import 'workout_exercises.dart';

/// A single set.
///
/// The most-written table in the app and the one the whole product is built
/// around: inserting a row here is the action the user performs dozens of
/// times per workout, and it must complete against local storage alone.
@TableIndex(name: 'idx_workout_sets_exercise', columns: {#workoutExerciseId})
@TableIndex(name: 'idx_workout_sets_completed_at', columns: {#completedAt})
class WorkoutSets extends Table with SyncedTable {
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id)();

  /// Ordinal within the exercise, starting at 1.
  ///
  /// Warm-up sets occupy a number like any other; the UI renders `W` in place
  /// of the digit rather than the data leaving a gap.
  IntColumn get setNumber => integer()();

  TextColumn get type =>
      textEnum<SetType>().withDefault(Constant(SetType.normal.name))();

  /// Load in **kilograms**, always.
  ///
  /// Unit preference is a display concern; storing one canonical unit keeps
  /// volume sums and personal records comparable across a user who switches
  /// preference midway. Null for bodyweight movements.
  RealColumn get weight => real().nullable()();

  IntColumn get reps => integer().nullable()();

  /// Reps in reserve — how many more the user felt they had left.
  IntColumn get rir => integer().nullable()();

  /// Whether the set has been checked off.
  ///
  /// A planned-but-unperformed set still exists as a row so the workout screen
  /// can render the full plan; only completed sets count towards volume.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// When the set was checked off. Null while [completed] is false.
  DateTimeColumn get completedAt => dateTime().nullable()();
}
