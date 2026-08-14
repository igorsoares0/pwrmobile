import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';

/// Parses the real shipped catalogue straight off disk.
///
/// Reading the actual asset rather than a fixture means a bad edit to
/// `assets/catalog/exercises.json` fails these tests instead of production.
ExerciseCatalog loadTestCatalog() => ExerciseCatalog.parse(
  File('assets/catalog/exercises.json').readAsStringSync(),
);

void main() {
  late AppDatabase db;
  late ExerciseRepository exercises;
  late RoutineRepository routines;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exercises = ExerciseRepository(db, loadTestCatalog());
    routines = RoutineRepository(db);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Exercise> newExercise({
    String name = 'Supino reto',
    MuscleGroup muscleGroup = MuscleGroup.chest,
    Equipment equipment = Equipment.barbell,
  }) {
    return exercises.create(
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
    );
  }

  group('sync invariants', () {
    test('an edit bumps version and moves updatedAt forward', () async {
      final exercise = await newExercise();
      expect(exercise.version, 1);

      await exercises.update(exercise.id, name: 'Supino barra');
      final updated = await exercises.findById(exercise.id);

      expect(updated!.name, 'Supino barra');
      expect(updated.version, 2);
      expect(
        updated.updatedAt.isAfter(exercise.updatedAt) ||
            updated.updatedAt.isAtSameMomentAs(exercise.updatedAt),
        isTrue,
      );
    });

    test('delete tombstones the row instead of removing it', () async {
      final exercise = await newExercise();
      await exercises.delete(exercise.id);

      expect(await exercises.findById(exercise.id), isNull);

      final raw = await db
          .customSelect(
            'SELECT deleted_at, version FROM exercises WHERE id = ?',
            variables: [Variable<String>(exercise.id)],
          )
          .getSingle();

      expect(raw.read<String?>('deleted_at'), isNotNull);
      expect(raw.read<int>('version'), 2);
    });

    test('deleting twice is idempotent', () async {
      final exercise = await newExercise();
      await exercises.delete(exercise.id);
      await exercises.delete(exercise.id);

      final raw = await db
          .customSelect(
            'SELECT version FROM exercises WHERE id = ?',
            variables: [Variable<String>(exercise.id)],
          )
          .getSingle();

      // A second delete must not inflate the revision — that would queue a
      // pointless sync operation for a row that already went out as deleted.
      expect(raw.read<int>('version'), 2);
    });

    test('tombstoned rows disappear from every read path', () async {
      final kept = await newExercise(name: 'Agachamento');
      final removed = await newExercise(name: 'Leg press');
      await exercises.delete(removed.id);

      final library = await exercises.watchLibrary().first;
      expect(library.map((e) => e.id), [kept.id]);
    });
  });

  group('ExerciseRepository', () {
    test('filters by coarse region', () async {
      await newExercise(name: 'Supino', muscleGroup: MuscleGroup.chest);
      await newExercise(name: 'Rosca', muscleGroup: MuscleGroup.biceps);
      await newExercise(
        name: 'Tríceps testa',
        muscleGroup: MuscleGroup.triceps,
      );

      final arms = await exercises
          .watchLibrary(region: MuscleGroupRegion.arms)
          .first;

      // biceps and triceps both roll up into "arms".
      expect(arms.map((e) => e.name), ['Rosca', 'Tríceps testa']);
    });

    test('searches by name, case-insensitively', () async {
      await newExercise(name: 'Supino inclinado');
      await newExercise(name: 'Agachamento livre');

      final found = await exercises.watchLibrary(search: 'supino').first;
      expect(found.map((e) => e.name), ['Supino inclinado']);
    });

    test('user-created exercises are flagged as custom', () async {
      final exercise = await newExercise();
      expect(exercise.isCustom, isTrue);
    });

    test('counts the library by region', () async {
      await newExercise(name: 'Supino', muscleGroup: MuscleGroup.chest);
      await newExercise(name: 'Crucifixo', muscleGroup: MuscleGroup.chest);
      await newExercise(name: 'Agachamento', muscleGroup: MuscleGroup.quads);

      final counts = await exercises.countByRegion();
      expect(counts[MuscleGroupRegion.chest], 2);
      expect(counts[MuscleGroupRegion.legs], 1);
    });
  });

  group('RoutineRepository', () {
    test('counts routines and excludes deleted ones', () async {
      final a = await routines.create(name: 'Push A');
      await routines.create(name: 'Pull B');
      expect(await routines.countRoutines(), 2);

      await routines.delete(a.id);
      expect(await routines.countRoutines(), 1);
    });

    test('summaries carry the exercise count', () async {
      final routine = await routines.create(name: 'Push A', focus: 'Peito');
      final bench = await newExercise();
      final fly = await newExercise(name: 'Crucifixo');

      await routines.addExercise(routineId: routine.id, exerciseId: bench.id);
      await routines.addExercise(routineId: routine.id, exerciseId: fly.id);

      final summaries = await routines.watchRoutines().first;
      expect(summaries, hasLength(1));
      expect(summaries.single.routine.focus, 'Peito');
      expect(summaries.single.exerciseCount, 2);
    });

    test('a routine with no exercises reports a count of zero', () async {
      await routines.create(name: 'Empty');

      final summaries = await routines.watchRoutines().first;
      expect(summaries.single.exerciseCount, 0);
    });

    test('slots are appended in order and resolve the exercise', () async {
      final routine = await routines.create(name: 'Push A');
      final bench = await newExercise();
      final fly = await newExercise(name: 'Crucifixo');

      await routines.addExercise(routineId: routine.id, exerciseId: bench.id);
      await routines.addExercise(routineId: routine.id, exerciseId: fly.id);

      final slots = await routines.watchExercises(routine.id).first;
      expect(slots.map((s) => s.exercise.name), ['Supino reto', 'Crucifixo']);
      expect(slots.map((s) => s.entry.position), [0, 1]);
    });

    test('reordering rewrites absolute positions', () async {
      final routine = await routines.create(name: 'Push A');
      final first = await newExercise(name: 'A');
      final second = await newExercise(name: 'B');
      final third = await newExercise(name: 'C');

      final slotA = await routines.addExercise(
        routineId: routine.id,
        exerciseId: first.id,
      );
      final slotB = await routines.addExercise(
        routineId: routine.id,
        exerciseId: second.id,
      );
      final slotC = await routines.addExercise(
        routineId: routine.id,
        exerciseId: third.id,
      );

      await routines.reorderExercises([slotC.id, slotA.id, slotB.id]);

      final slots = await routines.watchExercises(routine.id).first;
      expect(slots.map((s) => s.exercise.name), ['C', 'A', 'B']);
      expect(slots.map((s) => s.entry.position), [0, 1, 2]);
    });

    test('deleting a routine tombstones its slots too', () async {
      final routine = await routines.create(name: 'Push A');
      final bench = await newExercise();
      await routines.addExercise(routineId: routine.id, exerciseId: bench.id);

      await routines.delete(routine.id);

      expect(await routines.watchExercises(routine.id).first, isEmpty);
      expect(await routines.watchRoutines().first, isEmpty);
      // The exercise itself is untouched — it belongs to the library.
      expect(await exercises.findById(bench.id), isNotNull);
    });
  });

  group('WorkoutRepository — starting a session', () {
    test('copies routine slots and pre-creates the planned sets', () async {
      final routine = await routines.create(name: 'Push A');
      final bench = await newExercise();
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: bench.id,
        targetSets: 4,
        targetReps: 8,
        restSeconds: 120,
      );

      final session = await workouts.startFromRoutine(routine.id);
      final details = await workouts.watchSessionExercises(session.id).first;

      expect(details, hasLength(1));
      expect(details.single.exercise.name, 'Supino reto');
      expect(details.single.entry.restSeconds, 120);
      expect(details.single.sets, hasLength(4));
      expect(details.single.sets.map((s) => s.setNumber), [1, 2, 3, 4]);
      expect(details.single.sets.every((s) => s.completed), isFalse);
      // With no history to draw on, reps fall back to the routine's target.
      expect(details.single.sets.first.reps, 8);
      expect(details.single.sets.first.weight, isNull);
    });

    test('refuses to start a second workout while one is open', () async {
      final routine = await routines.create(name: 'Push A');
      await workouts.startEmpty();

      await expectLater(
        workouts.startFromRoutine(routine.id),
        throwsA(isA<StateError>()),
      );
    });

    test('a discarded session frees the slot for a new one', () async {
      final first = await workouts.startEmpty();
      await workouts.discard(first.id);

      final second = await workouts.startEmpty();
      expect(second.id, isNot(first.id));
      expect(await workouts.activeSession(), isNotNull);
    });

    test('the active session is the unfinished one', () async {
      final session = await workouts.startEmpty();
      expect((await workouts.watchActiveSession().first)?.id, session.id);

      await workouts.finish(session.id);
      expect(await workouts.watchActiveSession().first, isNull);
    });
  });

  group('WorkoutRepository — logging sets', () {
    test('completing a set stamps completedAt and bumps version', () async {
      final session = await workouts.startEmpty();
      final bench = await newExercise();
      final workoutExercise = await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 1,
      );

      final details = await workouts.watchSessionExercises(session.id).first;
      final set = details.single.sets.single;
      expect(set.completed, isFalse);

      await workouts.completeSet(set.id, weight: 80, reps: 8);

      final after = await workouts.watchSessionExercises(session.id).first;
      final completed = after.single.sets.single;

      expect(completed.completed, isTrue);
      expect(completed.completedAt, isNotNull);
      expect(completed.weight, 80);
      expect(completed.reps, 8);
      expect(completed.version, greaterThan(set.version));
      expect(workoutExercise.sessionId, session.id);
    });

    test('the session stream re-emits when a set is checked off', () async {
      final session = await workouts.startEmpty();
      final bench = await newExercise();
      await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 1,
      );

      final emissions = <List<WorkoutExerciseDetail>>[];
      final subscription = workouts
          .watchSessionExercises(session.id)
          .listen(emissions.add);
      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(emissions.single.single.sets.single.completed, isFalse);

      final setId = emissions.single.single.sets.single.id;
      await workouts.completeSet(setId, weight: 80, reps: 8);
      await pumpEventQueue();
      await subscription.cancel();

      // The workout screen renders off this stream. If checking a set off does
      // not push a new value, the checkmark never appears.
      expect(emissions.length, greaterThan(1));
      expect(emissions.last.single.sets.single.completed, isTrue);
      expect(emissions.last.single.sets.single.weight, 80);
    });

    test('an exercise with no sets still appears in the stream', () async {
      final session = await workouts.startEmpty();
      final bench = await newExercise();
      await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 0,
      );

      final details = await workouts.watchSessionExercises(session.id).first;

      expect(details, hasLength(1));
      expect(details.single.sets, isEmpty);
    });

    test('un-completing clears the timestamp', () async {
      final set = await _loggedSet(workouts, exercises, weight: 80, reps: 8);
      await workouts.uncompleteSet(set.id);

      final row = await (db.select(
        db.workoutSets,
      )..where((t) => t.id.equals(set.id))).getSingle();

      expect(row.completed, isFalse);
      expect(row.completedAt, isNull);
    });

    test('added sets continue the numbering', () async {
      final session = await workouts.startEmpty();
      final bench = await newExercise();
      final workoutExercise = await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 2,
      );

      final extra = await workouts.addSet(
        workoutExercise.id,
        type: SetType.dropSet,
      );

      expect(extra.setNumber, 3);
      expect(extra.type, SetType.dropSet);
    });
  });

  group('WorkoutRepository — volume', () {
    test('warm-ups and unchecked sets do not count', () async {
      final session = await workouts.startEmpty();
      final bench = await newExercise();
      final workoutExercise = await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 0,
      );

      final warmup = await workouts.addSet(
        workoutExercise.id,
        type: SetType.warmup,
      );
      final working = await workouts.addSet(workoutExercise.id);
      final skipped = await workouts.addSet(workoutExercise.id);

      await workouts.completeSet(warmup.id, weight: 40, reps: 12);
      await workouts.completeSet(working.id, weight: 80, reps: 8);
      // `skipped` stays unchecked.
      await workouts.updateSet(skipped.id, weight: 100, reps: 10);

      await workouts.finish(session.id);
      final stats = await workouts.sessionStats(session.id);

      // Only the working set: 80 × 8.
      expect(stats!.volume, 640);
      expect(stats.completedSetCount, 2);
      expect(stats.exerciseCount, 1);
    });

    test('history reports totals per finished session', () async {
      await _loggedSet(workouts, exercises, weight: 100, reps: 5, finish: true);
      await _loggedSet(workouts, exercises, weight: 60, reps: 10, finish: true);

      final history = await workouts.watchHistory().first;

      expect(history, hasLength(2));
      // Newest first.
      expect(history.first.volume, 600);
      expect(history.last.volume, 500);
      expect(history.first.duration, isNotNull);
    });

    test('an unfinished session stays out of history', () async {
      await workouts.startEmpty();
      expect(await workouts.watchHistory().first, isEmpty);
    });
  });

  group('WorkoutRepository — previous performance', () {
    test('returns nothing before the first finished session', () async {
      final bench = await newExercise();
      expect(await workouts.previousPerformance(bench.id), isNull);
    });

    test('ignores sessions that were never finished', () async {
      final bench = await newExercise();
      final session = await workouts.startEmpty();
      final workoutExercise = await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 1,
      );
      final sets = await workouts.watchSessionExercises(session.id).first;
      await workouts.completeSet(
        sets.single.sets.single.id,
        weight: 80,
        reps: 8,
      );
      expect(workoutExercise.exerciseId, bench.id);

      // Still open, so it is not a performance to compare against.
      expect(await workouts.previousPerformance(bench.id), isNull);
    });

    test('reports the last finished session and its best set', () async {
      final bench = await newExercise();
      final session = await workouts.startEmpty();
      final workoutExercise = await workouts.addExercise(
        sessionId: session.id,
        exerciseId: bench.id,
        targetSets: 3,
      );

      final detail = await workouts.watchSessionExercises(session.id).first;
      final sets = detail.single.sets;
      await workouts.completeSet(sets[0].id, weight: 80, reps: 8);
      await workouts.completeSet(sets[1].id, weight: 85, reps: 6);
      await workouts.completeSet(sets[2].id, weight: 85, reps: 4);
      await workouts.finish(session.id);

      final previous = await workouts.previousPerformance(bench.id);

      expect(previous, isNotNull);
      expect(previous!.sets, hasLength(3));
      expect(previous.workingSetCount, 3);
      // 85×6 beats 85×4 on the rep tiebreaker, and 80×8 on weight.
      expect(previous.bestSet!.weight, 85);
      expect(previous.bestSet!.reps, 6);
      expect(previous.volume, 80 * 8 + 85 * 6 + 85 * 4);
      expect(workoutExercise.sessionId, session.id);
    });

    test('excludes the session it is called from', () async {
      final bench = await newExercise();

      final first = await workouts.startEmpty();
      final firstExercise = await workouts.addExercise(
        sessionId: first.id,
        exerciseId: bench.id,
        targetSets: 1,
      );
      var detail = await workouts.watchSessionExercises(first.id).first;
      await workouts.completeSet(
        detail.single.sets.single.id,
        weight: 80,
        reps: 8,
      );
      await workouts.finish(first.id);

      final second = await workouts.startEmpty();
      await workouts.addExercise(
        sessionId: second.id,
        exerciseId: bench.id,
        targetSets: 1,
      );
      detail = await workouts.watchSessionExercises(second.id).first;
      await workouts.completeSet(
        detail.single.sets.single.id,
        weight: 90,
        reps: 6,
      );
      await workouts.finish(second.id);

      final fromSecond = await workouts.previousPerformance(
        bench.id,
        excludeSessionId: second.id,
      );

      expect(fromSecond!.session.id, first.id);
      expect(fromSecond.bestSet!.weight, 80);
      expect(firstExercise.sessionId, first.id);
    });

    test('seeds the next session with what was lifted last time', () async {
      final bench = await newExercise();
      final routine = await routines.create(name: 'Push A');
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: bench.id,
        targetSets: 2,
        targetReps: 10,
      );

      final first = await workouts.startFromRoutine(routine.id);
      var detail = await workouts.watchSessionExercises(first.id).first;
      await workouts.completeSet(detail.single.sets[0].id, weight: 80, reps: 8);
      await workouts.completeSet(detail.single.sets[1].id, weight: 85, reps: 6);
      await workouts.finish(first.id);

      final second = await workouts.startFromRoutine(routine.id);
      detail = await workouts.watchSessionExercises(second.id).first;

      // This is the behaviour that makes the app beat a notebook: the second
      // session opens already filled in with the first.
      expect(detail.single.sets[0].weight, 80);
      expect(detail.single.sets[0].reps, 8);
      expect(detail.single.sets[1].weight, 85);
      expect(detail.single.sets[1].reps, 6);
      expect(detail.single.sets.every((s) => s.completed), isFalse);
    });
  });
}

/// Runs a one-set workout and returns the set. Optionally finishes the session.
Future<WorkoutSet> _loggedSet(
  WorkoutRepository workouts,
  ExerciseRepository exercises, {
  required double weight,
  required int reps,
  bool finish = false,
}) async {
  final exercise = await exercises.create(
    name: 'Exercise ${DateTime.now().microsecondsSinceEpoch}',
    muscleGroup: MuscleGroup.chest,
    equipment: Equipment.barbell,
  );

  final session = await workouts.startEmpty();
  await workouts.addExercise(
    sessionId: session.id,
    exerciseId: exercise.id,
    targetSets: 1,
  );

  final detail = await workouts.watchSessionExercises(session.id).first;
  final set = detail.single.sets.single;
  await workouts.completeSet(set.id, weight: weight, reps: reps);

  if (finish) await workouts.finish(session.id);

  return set;
}
