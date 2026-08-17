// drift exports a top-level `isNull` for building SQL predicates, which
// collides with the matcher of the same name. The predicate is still reachable
// as the `.isNull()` method on a column.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/enums.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('schema', () {
    test('creates every table', () async {
      final rows = await db
          .customSelect(
            'SELECT name FROM sqlite_master '
            '''WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ''',
          )
          .get();

      final names = rows.map((row) => row.read<String>('name')).toSet();

      expect(names, {
        'exercises',
        'routines',
        'routine_exercises',
        'workout_sessions',
        'workout_exercises',
        'workout_sets',
        'sync_operations',
        // Device-local preferences; deliberately not a synchronised entity.
        'app_settings',
        'body_measurements',
      });
    });

    test(
      'stores timestamps as text so sub-second precision survives',
      () async {
        final rows = await db
            .customSelect(
              "SELECT name, type FROM pragma_table_info('exercises')",
            )
            .get();

        final types = {
          for (final row in rows)
            row.read<String>('name'): row.read<String>('type'),
        };

        expect(types['created_at'], 'TEXT');
        expect(types['updated_at'], 'TEXT');
        expect(types['deleted_at'], 'TEXT');
      },
    );

    test('enforces foreign keys', () async {
      await expectLater(
        db
            .into(db.routineExercises)
            .insert(
              RoutineExercisesCompanion.insert(
                routineId: 'does-not-exist',
                exerciseId: 'does-not-exist-either',
                position: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('sync metadata', () {
    test('mints a client-side id and defaults the sync columns', () async {
      final exercise = await db
          .into(db.exercises)
          .insertReturning(
            ExercisesCompanion.insert(
              name: 'Supino reto',
              muscleGroup: MuscleGroup.chest,
              equipment: Equipment.barbell,
            ),
          );

      expect(exercise.id, isNotEmpty);
      expect(exercise.version, 1);
      expect(exercise.deletedAt, isNull);
      expect(exercise.createdAt.isUtc, isTrue);
      expect(exercise.isCustom, isFalse);
    });

    test('ids sort by creation time across milliseconds', () async {
      final ids = <String>[];
      for (var i = 0; i < 5; i++) {
        final row = await db
            .into(db.exercises)
            .insertReturning(
              ExercisesCompanion.insert(
                name: 'Exercise $i',
                muscleGroup: MuscleGroup.back,
                equipment: Equipment.cable,
              ),
            );
        ids.add(row.id);

        // UUID v7 orders by its millisecond timestamp prefix; the bits below
        // that are random, so ids minted inside the same millisecond have no
        // defined order. The delay is what makes this assertion meaningful
        // rather than lucky.
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }

      expect(ids, orderedEquals([...ids]..sort()));
    });
  });

  group('enum storage', () {
    test('round-trips enums by name, not index', () async {
      final exercise = await db
          .into(db.exercises)
          .insertReturning(
            ExercisesCompanion.insert(
              name: 'Agachamento livre',
              muscleGroup: MuscleGroup.quads,
              equipment: Equipment.barbell,
            ),
          );

      expect(exercise.muscleGroup, MuscleGroup.quads);

      final raw = await db
          .customSelect(
            'SELECT muscle_group FROM exercises WHERE id = ?',
            variables: [Variable<String>(exercise.id)],
          )
          .getSingle();

      expect(raw.read<String>('muscle_group'), 'quads');
    });

    test('a set defaults to the normal type', () async {
      final set = await _insertSet(db);

      expect(set.type, SetType.normal);
      expect(set.completed, isFalse);
      expect(set.completedAt, isNull);
    });
  });

  group('workout graph', () {
    test('links session to exercise to set', () async {
      final set = await _insertSet(db);

      final query = db.select(db.workoutSets).join([
        innerJoin(
          db.workoutExercises,
          db.workoutExercises.id.equalsExp(db.workoutSets.workoutExerciseId),
        ),
        innerJoin(
          db.workoutSessions,
          db.workoutSessions.id.equalsExp(db.workoutExercises.sessionId),
        ),
        innerJoin(
          db.exercises,
          db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
        ),
      ])..where(db.workoutSets.id.equals(set.id));

      final row = await query.getSingle();

      expect(row.readTable(db.exercises).name, 'Supino reto');
      expect(row.readTable(db.workoutSessions).finishedAt, isNull);
      expect(row.readTable(db.workoutSets).weight, 80);
    });

    test('an unfinished session is the one in progress', () async {
      await _insertSet(db);

      final inProgress = await (db.select(
        db.workoutSessions,
      )..where((s) => s.finishedAt.isNull() & s.deletedAt.isNull())).get();

      expect(inProgress, hasLength(1));
    });
  });

  group('sync queue', () {
    test(
      'accepts an operation for an entity it holds no reference to',
      () async {
        // No foreign key on entity_id by design: a queued delete has to survive
        // the row it refers to disappearing.
        final operation = await db
            .into(db.syncOperations)
            .insertReturning(
              SyncOperationsCompanion.insert(
                entityType: SyncEntityType.workoutSet,
                entityId: 'a-row-that-is-already-gone',
                operation: SyncOperationType.delete,
                payload: '{"id":"a-row-that-is-already-gone"}',
              ),
            );

        expect(operation.attempts, 0);
        expect(operation.syncedAt, isNull);
        expect(operation.lastError, isNull);
      },
    );
  });
}

/// Builds the minimal exercise → session → workout exercise → set chain and
/// returns the set.
Future<WorkoutSet> _insertSet(AppDatabase db) async {
  final exercise = await db
      .into(db.exercises)
      .insertReturning(
        ExercisesCompanion.insert(
          name: 'Supino reto',
          muscleGroup: MuscleGroup.chest,
          equipment: Equipment.barbell,
        ),
      );

  final session = await db
      .into(db.workoutSessions)
      .insertReturning(const WorkoutSessionsCompanion());

  final workoutExercise = await db
      .into(db.workoutExercises)
      .insertReturning(
        WorkoutExercisesCompanion.insert(
          sessionId: session.id,
          exerciseId: exercise.id,
          position: 0,
        ),
      );

  return db
      .into(db.workoutSets)
      .insertReturning(
        WorkoutSetsCompanion.insert(
          workoutExerciseId: workoutExercise.id,
          setNumber: 1,
          weight: const Value(80),
          reps: const Value(8),
        ),
      );
}
