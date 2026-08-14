import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/catalog_provider.dart';
import '../../catalog/exercise_catalog.dart';
import '../app_database.dart';
import '../database_provider.dart';
import '../enums.dart';
import 'repository.dart';

/// The exercise library.
class ExerciseRepository extends Repository {
  const ExerciseRepository(super.db, this.catalog);

  /// The bundled catalogue, needed to search in the user's own language.
  final ExerciseCatalog catalog;

  /// Watches the library, optionally narrowed to a filter chip and a search
  /// term.
  ///
  /// [region] is the coarse bucket the library filters expose; it expands to
  /// every [MuscleGroup] that rolls up into it.
  Stream<List<Exercise>> watchLibrary({
    MuscleGroupRegion? region,
    String? search,
  }) {
    final query = db.select(db.exercises)
      ..where((tbl) => tbl.deletedAt.isNull());

    if (region != null) {
      final groups = MuscleGroup.values
          .where((group) => group.region == region)
          .toList();
      query.where((tbl) => tbl.muscleGroup.isInValues(groups));
    }

    final term = search?.trim();
    if (term != null && term.isNotEmpty) {
      // The `name` column holds English for catalogue rows, so a SQL LIKE
      // alone would never find "supino". Localised names live in the
      // catalogue, so matching slugs are resolved there first; the LIKE is
      // kept for user-created exercises, which have no slug and whose name is
      // already in the user's language.
      final slugs = catalog.slugsMatching(term);
      query.where((tbl) => tbl.slug.isIn(slugs) | tbl.name.like('%$term%'));
    }

    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch();
  }

  Stream<Exercise?> watchById(String id) {
    return (db.select(db.exercises)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<Exercise?> findById(String id) {
    return (db.select(db.exercises)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Creates a user-defined exercise.
  Future<Exercise> create({
    required String name,
    required MuscleGroup muscleGroup,
    required Equipment equipment,
    String? notes,
  }) {
    return db
        .into(db.exercises)
        .insertReturning(
          ExercisesCompanion.insert(
            name: name.trim(),
            muscleGroup: muscleGroup,
            equipment: equipment,
            notes: Value(notes),
            isCustom: const Value(true),
          ),
        );
  }

  /// Edits an exercise. Only the named arguments provided are written.
  ///
  /// Seeded exercises are editable too: a rename has to reach the user's other
  /// devices, which is why they carry sync metadata like any other row.
  Future<void> update(
    String id, {
    String? name,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
    String? notes,
  }) {
    return db.transaction(() async {
      await (db.update(db.exercises)..where((tbl) => tbl.id.equals(id))).write(
        ExercisesCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          muscleGroup: Value.absentIfNull(muscleGroup),
          equipment: Value.absentIfNull(equipment),
          notes: Value.absentIfNull(notes),
        ),
      );
      await touch(db.exercises, id);
    });
  }

  /// Tombstones an exercise.
  ///
  /// Workout history keeps resolving afterwards: sessions reference the row,
  /// and the row survives.
  Future<void> delete(String id) => softDelete(db.exercises, id);

  /// How many exercises the library currently holds, per coarse bucket.
  ///
  /// Feeds the `PEITO · 12 EXERCÍCIOS` heading above each filtered list.
  Future<Map<MuscleGroupRegion, int>> countByRegion() async {
    final rows = await (db.select(
      db.exercises,
    )..where((tbl) => tbl.deletedAt.isNull())).get();

    final counts = <MuscleGroupRegion, int>{};
    for (final exercise in rows) {
      final region = exercise.muscleGroup.region;
      counts[region] = (counts[region] ?? 0) + 1;
    }
    return counts;
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(exerciseCatalogProvider),
  ),
);
