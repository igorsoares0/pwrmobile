import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/workout/workout_blocks.dart';

/// Grouping is exercised against real rows rather than hand-built models: the
/// property under test is that a chain set up in the routine builder survives
/// into the session, and only the database can say whether it does.
void main() {
  late AppDatabase db;
  late RoutineRepository routines;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    routines = RoutineRepository(db);
    exercises = ExerciseRepository(db, catalog);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Builds a routine of [count] exercises, chains it per [chainedWithNext],
  /// and returns the blocks its session comes out as.
  Future<List<WorkoutBlock>> blocksFor(
    int count,
    List<bool> chainedWithNext,
  ) async {
    final routine = await routines.create(name: 'Push A');

    for (var i = 0; i < count; i++) {
      final exercise = await exercises.create(
        name: 'Exercise ${i + 1}',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
        targetSets: 1,
        restSeconds: 60,
      );
    }

    await routines.setSupersetChains(routine.id, chainedWithNext);
    final session = await workouts.startFromRoutine(routine.id);

    return blocksOf(await workouts.watchSessionExercises(session.id).first);
  }

  test('a routine with no chains is one block per exercise', () async {
    final blocks = await blocksFor(3, [false, false, false]);

    expect(blocks, hasLength(3));
    expect(blocks.every((block) => block.isSuperset), isFalse);
    // No letter, because there is nothing to tell apart.
    expect(blocks.map((block) => block.letter), everyElement(isNull));
  });

  test('a chained pair becomes one block, labelled A1 and A2', () async {
    final blocks = await blocksFor(3, [true, false, false]);

    expect(blocks, hasLength(2));
    expect(blocks.first.members, hasLength(2));
    expect(blocks.first.labelFor(0), 'A1');
    expect(blocks.first.labelFor(1), 'A2');

    // The exercise after the pair stands alone and stays unlabelled.
    expect(blocks.last.isSuperset, isFalse);
    expect(blocks.last.labelFor(0), isNull);
  });

  test('three in a row is one block of three, not a pair plus one', () async {
    final blocks = await blocksFor(3, [true, true, false]);

    expect(blocks, hasLength(1));
    expect(blocks.single.members, hasLength(3));
    expect(blocks.single.labelFor(2), 'A3');
  });

  test('two separate chains get their own letters', () async {
    final blocks = await blocksFor(4, [true, false, true, false]);

    expect(blocks, hasLength(2));
    expect(blocks.first.letter, 'A');
    expect(blocks.last.letter, 'B');
  });

  test('a group id nobody shares is not a superset', () async {
    // Reachable by removing one half of a pair mid-workout: the survivor keeps
    // a group id that now describes a chain of one. A block of one is a plain
    // exercise whatever the column says, and labelling it `A1` would promise a
    // partner that is not there.
    final routine = await routines.create(name: 'Push A');
    for (var i = 0; i < 2; i++) {
      final exercise = await exercises.create(
        name: 'Exercise ${i + 1}',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
        targetSets: 1,
        restSeconds: 60,
      );
    }
    final session = await workouts.startFromRoutine(routine.id);
    final details = await workouts.watchSessionExercises(session.id).first;

    final orphaned = [
      WorkoutExerciseDetail(
        entry: details.first.entry.copyWith(supersetGroup: const Value(7)),
        exercise: details.first.exercise,
        sets: details.first.sets,
      ),
      details.last,
    ];

    final blocks = blocksOf(orphaned);

    expect(blocks, hasLength(2));
    expect(blocks.first.isSuperset, isFalse);
    expect(blocks.first.letter, isNull);
  });

  test('an empty session has no blocks', () {
    expect(blocksOf(const []), isEmpty);
  });
}
