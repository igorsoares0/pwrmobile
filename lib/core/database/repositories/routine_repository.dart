import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../database_provider.dart';
import 'models.dart';
import 'repository.dart';

/// Routine templates and the exercise slots inside them.
class RoutineRepository extends Repository {
  const RoutineRepository(super.db);

  /// Watches every routine with the counts the home screen shows.
  Stream<List<RoutineSummary>> watchRoutines() {
    final exerciseCount = db.routineExercises.id.count();
    final plannedSets = db.routineExercises.targetSets.sum();
    const plannedRest = CustomExpression<int>(
      'COALESCE(SUM(routine_exercises.target_sets * '
      'routine_exercises.rest_seconds), 0)',
    );

    final query =
        db.select(db.routines).join([
            leftOuterJoin(
              db.routineExercises,
              db.routineExercises.routineId.equalsExp(db.routines.id) &
                  db.routineExercises.deletedAt.isNull(),
            ),
          ])
          ..addColumns([exerciseCount, plannedSets, plannedRest])
          ..where(db.routines.deletedAt.isNull())
          ..groupBy([db.routines.id])
          ..orderBy([OrderingTerm.asc(db.routines.position)]);

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => RoutineSummary(
              routine: row.readTable(db.routines),
              exerciseCount: row.read(exerciseCount) ?? 0,
              plannedSets: row.read(plannedSets) ?? 0,
              plannedRestSeconds: row.read(plannedRest) ?? 0,
            ),
          )
          .toList();
    });
  }

  /// One-shot read of a routine.
  ///
  /// Prefer this over `watchById(...).first` when a single value is what is
  /// wanted: taking the first element of a watch opens a query stream and
  /// immediately closes it, which leaves drift's cache-expiry timer churning
  /// for a read that never needed to be live.
  Future<Routine?> findById(String id) {
    return (db.select(db.routines)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// One-shot read of a routine's slots, resolved against the library.
  Future<List<RoutineExerciseDetail>> exercisesOf(String routineId) async {
    final rows =
        await (db.select(db.routineExercises).join([
                innerJoin(
                  db.exercises,
                  db.exercises.id.equalsExp(db.routineExercises.exerciseId),
                ),
              ])
              ..where(
                db.routineExercises.routineId.equals(routineId) &
                    db.routineExercises.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm.asc(db.routineExercises.position)]))
            .get();

    return [
      for (final row in rows)
        RoutineExerciseDetail(
          entry: row.readTable(db.routineExercises),
          exercise: row.readTable(db.exercises),
        ),
    ];
  }

  Stream<Routine?> watchById(String id) {
    return (db.select(db.routines)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  /// How many routines the user currently has.
  ///
  /// The Free plan caps this at three (spec §12), but the cap is not enforced
  /// here: the limit depends on the PRO entitlement, which does not exist until
  /// Phase 4. The subscription layer reads this count and decides.
  Future<int> countRoutines() async {
    final count = db.routines.id.count();
    final query = db.selectOnly(db.routines)
      ..addColumns([count])
      ..where(db.routines.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<Routine> create({
    required String name,
    String? focus,
    String? notes,
  }) async {
    return db.transaction(() async {
      final position = await _nextRoutinePosition();
      return db
          .into(db.routines)
          .insertReturning(
            RoutinesCompanion.insert(
              name: name.trim(),
              focus: Value(focus?.trim()),
              notes: Value(notes),
              position: Value(position),
            ),
          );
    });
  }

  Future<void> update(String id, {String? name, String? focus, String? notes}) {
    return db.transaction(() async {
      await (db.update(db.routines)..where((tbl) => tbl.id.equals(id))).write(
        RoutinesCompanion(
          name: name == null ? const Value.absent() : Value(name.trim()),
          focus: focus == null ? const Value.absent() : Value(focus.trim()),
          notes: Value.absentIfNull(notes),
        ),
      );
      await touch(db.routines, id);
    });
  }

  /// Tombstones a routine.
  ///
  /// Its slots are tombstoned with it, but sessions started from it keep
  /// resolving — deleting a routine to free a Free-plan slot must not erase the
  /// history of having trained it.
  Future<void> delete(String id) {
    return db.transaction(() async {
      final slots =
          await (db.select(db.routineExercises)..where(
                (tbl) => tbl.routineId.equals(id) & tbl.deletedAt.isNull(),
              ))
              .get();

      for (final slot in slots) {
        await softDelete(db.routineExercises, slot.id);
      }
      await softDelete(db.routines, id);
    });
  }

  // --- Exercise slots -------------------------------------------------------

  /// Watches the slots of a routine, resolved against the exercise library and
  /// ordered as the user arranged them.
  Stream<List<RoutineExerciseDetail>> watchExercises(String routineId) {
    final query =
        db.select(db.routineExercises).join([
            innerJoin(
              db.exercises,
              db.exercises.id.equalsExp(db.routineExercises.exerciseId),
            ),
          ])
          ..where(
            db.routineExercises.routineId.equals(routineId) &
                db.routineExercises.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(db.routineExercises.position)]);

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => RoutineExerciseDetail(
              entry: row.readTable(db.routineExercises),
              exercise: row.readTable(db.exercises),
            ),
          )
          .toList();
    });
  }

  Future<RoutineExercise> addExercise({
    required String routineId,
    required String exerciseId,
    int targetSets = 3,
    int? targetReps,
    int restSeconds = 90,
    int? supersetGroup,
  }) {
    return db.transaction(() async {
      final position = await _nextSlotPosition(routineId);
      final slot = await db
          .into(db.routineExercises)
          .insertReturning(
            RoutineExercisesCompanion.insert(
              routineId: routineId,
              exerciseId: exerciseId,
              position: position,
              targetSets: Value(targetSets),
              targetReps: Value(targetReps),
              restSeconds: Value(restSeconds),
              supersetGroup: Value(supersetGroup),
            ),
          );

      // The routine itself changed shape, so its revision moves too — Phase 3
      // pushes the parent alongside the child.
      await touch(db.routines, routineId);
      return slot;
    });
  }

  Future<void> updateExercise(
    String slotId, {
    int? targetSets,
    int? targetReps,
    int? restSeconds,
    int? supersetGroup,
    bool clearSuperset = false,
    String? notes,
  }) {
    return db.transaction(() async {
      await (db.update(
        db.routineExercises,
      )..where((tbl) => tbl.id.equals(slotId))).write(
        RoutineExercisesCompanion(
          targetSets: Value.absentIfNull(targetSets),
          targetReps: Value.absentIfNull(targetReps),
          restSeconds: Value.absentIfNull(restSeconds),
          supersetGroup: clearSuperset
              ? const Value(null)
              : Value.absentIfNull(supersetGroup),
          notes: Value.absentIfNull(notes),
        ),
      );
      await touch(db.routineExercises, slotId);
    });
  }

  Future<void> removeExercise(String slotId) =>
      softDelete(db.routineExercises, slotId);

  /// Rewrites slot order after a drag.
  ///
  /// Takes the full ordered list rather than a moved-from/moved-to pair: the
  /// caller already holds the reordered list, and writing absolute positions
  /// avoids the gaps and collisions that incremental shuffling accumulates.
  Future<void> reorderExercises(List<String> orderedSlotIds) {
    return db.transaction(() async {
      for (var index = 0; index < orderedSlotIds.length; index++) {
        final slotId = orderedSlotIds[index];
        await (db.update(db.routineExercises)
              ..where((tbl) => tbl.id.equals(slotId)))
            .write(RoutineExercisesCompanion(position: Value(index)));
        await touch(db.routineExercises, slotId);
      }
    });
  }

  /// Rewrites which slots are chained into supersets.
  ///
  /// Takes one flag per slot, in order: "performed back to back with the next
  /// one". The group ids are recomputed from scratch rather than patched,
  /// because that is the only way to keep them consistent — a group id is
  /// shared by a run of slots, so editing one link can split, merge or dissolve
  /// a group, and incremental updates drift out of sync fast.
  ///
  /// The last flag is ignored: nothing follows the final slot.
  Future<void> setSupersetChains(String routineId, List<bool> chainedWithNext) {
    return db.transaction(() async {
      final slots =
          await (db.select(db.routineExercises)
                ..where(
                  (tbl) =>
                      tbl.routineId.equals(routineId) & tbl.deletedAt.isNull(),
                )
                ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
              .get();

      final groups = supersetGroupsFor(slots.length, chainedWithNext);

      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        if (slot.supersetGroup == groups[i]) continue;

        await (db.update(db.routineExercises)
              ..where((tbl) => tbl.id.equals(slot.id)))
            .write(RoutineExercisesCompanion(supersetGroup: Value(groups[i])));
        await touch(db.routineExercises, slot.id);
      }
    });
  }

  /// Assigns a group id to each slot in a run of chained slots, and null to
  /// slots that stand alone.
  ///
  /// Exposed for testing; the grouping rule is the part worth pinning down.
  static List<int?> supersetGroupsFor(int count, List<bool> chainedWithNext) {
    final groups = List<int?>.filled(count, null);
    var nextGroup = 0;

    for (var i = 0; i < count - 1; i++) {
      if (i >= chainedWithNext.length || !chainedWithNext[i]) continue;

      // Continue the run this slot already belongs to, or open a new one.
      final group = groups[i] ?? nextGroup++;
      groups[i] = group;
      groups[i + 1] = group;
    }

    return groups;
  }

  Future<int> _nextRoutinePosition() async {
    final max = db.routines.position.max();
    final query = db.selectOnly(db.routines)
      ..addColumns([max])
      ..where(db.routines.deletedAt.isNull());
    final row = await query.getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<int> _nextSlotPosition(String routineId) async {
    final max = db.routineExercises.position.max();
    final query = db.selectOnly(db.routineExercises)
      ..addColumns([max])
      ..where(
        db.routineExercises.routineId.equals(routineId) &
            db.routineExercises.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return (row.read(max) ?? -1) + 1;
  }
}

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => RoutineRepository(ref.watch(appDatabaseProvider)),
);
