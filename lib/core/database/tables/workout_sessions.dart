import 'package:drift/drift.dart';

import 'routines.dart';
import 'synced_table.dart';

/// One performed workout.
///
/// A session with a null [finishedAt] is the workout currently in progress —
/// there is at most one, and finding it is how the app restores state after
/// the process is killed mid-set.
@TableIndex(name: 'idx_workout_sessions_started_at', columns: {#startedAt})
@TableIndex(name: 'idx_workout_sessions_finished_at', columns: {#finishedAt})
class WorkoutSessions extends Table with SyncedTable {
  /// The routine this session was started from.
  ///
  /// Nullable: the user can start an empty workout and add exercises as they
  /// go. Routines are soft-deleted, so this reference keeps resolving even
  /// after the user deletes the routine to free a slot on the Free plan.
  TextColumn get routineId => text().nullable().references(Routines, #id)();

  DateTimeColumn get startedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Null while the workout is in progress.
  ///
  /// Once set, the session is treated as effectively immutable by the sync
  /// layer (spec §8) — finished workouts are history, not working state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  TextColumn get notes => text().nullable()();
}
