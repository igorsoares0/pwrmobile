import 'package:drift/drift.dart';

import '../enums.dart';
import 'synced_table.dart';

/// The exercise library.
///
/// Holds both the movements seeded with the app and the ones the user creates.
/// Rows are never hard-deleted, which is what lets workout history keep
/// resolving an exercise the user removed from their library months ago.
@TableIndex(name: 'idx_exercises_muscle_group', columns: {#muscleGroup})
@TableIndex(name: 'idx_exercises_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_exercises_slug', columns: {#slug}, unique: true)
class Exercises extends Table with SyncedTable {
  /// Catalogue key, or null for a user-created exercise.
  ///
  /// A non-null slug means the row came from the bundled catalogue: its
  /// display name is looked up per locale, and its [id] is derived from this
  /// slug, so every device agrees on it.
  ///
  /// This is the seam that makes the app work outside one country. The
  /// catalogue carries a name per locale; the database stores only the slug,
  /// so a user switching their phone to Spanish sees Spanish exercise names
  /// against the same history.
  TextColumn get slug => text().nullable().withLength(min: 1, max: 80)();

  /// Canonical English name.
  ///
  /// For a catalogue row this is the fallback shown when the user's locale has
  /// no translation. For a user-created exercise it is the literal name they
  /// typed, in whatever language they typed it.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get muscleGroup => textEnum<MuscleGroup>()();

  TextColumn get equipment => textEnum<Equipment>()();

  /// False for movements shipped with the app, true for user-created ones.
  ///
  /// Seeded exercises are still synchronized: a user may rename one, and that
  /// edit has to reach their other devices.
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// Free-form cues the user attaches to the movement.
  TextColumn get notes => text().nullable()();
}
