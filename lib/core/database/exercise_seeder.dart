import 'package:drift/drift.dart';

import '../catalog/exercise_catalog.dart';
import 'app_database.dart';
import 'tables/synced_table.dart';

/// Materialises the bundled catalogue into the `exercises` table.
///
/// Runs on every open, not just on create: an app update that adds exercises
/// to the catalogue has to reach users who installed before it shipped.
class ExerciseSeeder {
  const ExerciseSeeder(this.db);

  final AppDatabase db;

  /// Inserts every catalogue exercise the database does not already have.
  ///
  /// Existing rows are left completely alone. That is deliberate: a user may
  /// have renamed a catalogue exercise, and re-seeding must not overwrite the
  /// edit. It also keeps the operation from bumping `version` on untouched
  /// rows, which would queue a pointless sync push for the whole library on
  /// every app update.
  ///
  /// Returns how many rows were inserted.
  Future<int> seed(ExerciseCatalog catalog) async {
    final rows = catalog.exercises
        .map(
          (exercise) => ExercisesCompanion.insert(
            id: Value(catalogEntityId('exercise', exercise.slug)),
            slug: Value(exercise.slug),
            name: exercise.canonicalName,
            muscleGroup: exercise.muscleGroup,
            equipment: exercise.equipment,
          ),
        )
        .toList();

    final before = await _exerciseCount();
    await db.batch((batch) {
      // `DO NOTHING` rather than an upsert — see the note above about not
      // clobbering user edits.
      batch.insertAll(db.exercises, rows, mode: InsertMode.insertOrIgnore);
    });
    return await _exerciseCount() - before;
  }

  Future<int> _exerciseCount() async {
    final count = db.exercises.id.count();
    final query = db.selectOnly(db.exercises)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }
}
