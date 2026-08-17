import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/core/settings/weight_unit.dart';
import 'package:pwrmobile/features/profile/csv_export.dart';

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late ExerciseRepository exercises;
  late RoutineRepository routines;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    exercises = ExerciseRepository(db, catalog);
    routines = RoutineRepository(db);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  CsvExport exporter({WeightUnit unit = WeightUnit.kg}) => CsvExport(
    workouts: workouts,
    catalog: catalog,
    languageCode: 'en',
    unit: unit,
  );

  /// One finished session: bench press, two working sets and a warm-up.
  Future<void> loggedSession({String exerciseName = 'Bench press'}) async {
    final exercise = await exercises.create(
      name: exerciseName,
      muscleGroup: MuscleGroup.chest,
      equipment: Equipment.barbell,
    );
    final routine = await routines.create(name: 'Push');
    await routines.addExercise(
      routineId: routine.id,
      exerciseId: exercise.id,
      targetSets: 2,
    );

    final session = await workouts.startFromRoutine(routine.id);
    final details = await workouts.sessionExercises(session.id);
    final entry = details.single;

    await workouts.completeSet(entry.sets[0].id, weight: 80, reps: 8);
    await workouts.completeSet(entry.sets[1].id, weight: 82.5, reps: 6);

    final warmup = await workouts.addSet(entry.entry.id, type: SetType.warmup);
    await workouts.completeSet(warmup.id, weight: 40, reps: 12);

    await workouts.finish(session.id);
  }

  List<String> rowsOf(String csv) =>
      csv.split('\r\n').where((line) => line.isNotEmpty).toList();

  test('an empty log produces a header and nothing else', () async {
    final file = await exporter().build();

    expect(file.setCount, 0);
    expect(rowsOf(file.contents), hasLength(1));
    expect(file.contents, startsWith('date,started_at,finished_at,routine,'));
  });

  test('a finished session exports one row per completed set', () async {
    await loggedSession();

    final file = await exporter().build();
    final rows = rowsOf(file.contents);

    expect(file.setCount, 3);
    expect(rows, hasLength(4));
    expect(rows[1], contains('Push,Bench press,1,normal,80,8,640'));
    // 82.5 kg has to survive as 82.5: the volume formatter would round it to
    // 83 and the file would disagree with what the user logged.
    expect(rows[2], contains(',82.5,6,495'));
    // Warm-ups are exported and labelled, unlike in volume, so whoever opens
    // the file decides whether they count.
    expect(rows[3], contains(',warmup,40,12,480'));
  });

  test('unchecked sets never reach the file', () async {
    final exercise = await exercises.create(
      name: 'Squat',
      muscleGroup: MuscleGroup.quads,
      equipment: Equipment.barbell,
    );
    final routine = await routines.create(name: 'Legs');
    await routines.addExercise(
      routineId: routine.id,
      exerciseId: exercise.id,
      targetSets: 3,
    );

    final session = await workouts.startFromRoutine(routine.id);
    final entry = (await workouts.sessionExercises(session.id)).single;
    await workouts.completeSet(entry.sets.first.id, weight: 100, reps: 5);
    await workouts.finish(session.id);

    final file = await exporter().build();

    // Three sets were planned; one was performed.
    expect(file.setCount, 1);
  });

  test('a workout still in progress is not exported', () async {
    final exercise = await exercises.create(
      name: 'Row',
      muscleGroup: MuscleGroup.back,
      equipment: Equipment.barbell,
    );
    final routine = await routines.create(name: 'Pull');
    await routines.addExercise(
      routineId: routine.id,
      exerciseId: exercise.id,
      targetSets: 1,
    );

    final session = await workouts.startFromRoutine(routine.id);
    final entry = (await workouts.sessionExercises(session.id)).single;
    await workouts.completeSet(entry.sets.first.id, weight: 60, reps: 10);
    // Deliberately not finished.

    expect((await exporter().build()).setCount, 0);
  });

  test('loads are converted into the chosen unit, header included', () async {
    await loggedSession();

    final file = await exporter(unit: WeightUnit.lb).build();

    expect(file.contents, contains('weight_lb'));
    expect(file.contents, contains('volume_lb'));
    // 80 kg is 176.37 lb; 8 reps of it is 1410.96.
    expect(rowsOf(file.contents)[1], contains(',176.37,8,1410.96'));
  });

  test('a name with a comma stays in one column', () async {
    await loggedSession(exerciseName: 'Bench press, close grip');

    final file = await exporter().build();
    final row = rowsOf(file.contents)[1];

    expect(row, contains('"Bench press, close grip"'));
    // Header columns, and no more: the quoting is what keeps them aligned.
    expect(row.split(',').length, greaterThan(10));
    expect(
      RegExp(r'^[^,]*,[^,]*,[^,]*,[^,]*,"[^"]*",').hasMatch(row),
      isTrue,
      reason: 'the quoted name should occupy the fifth column alone',
    );
  });

  test('a quote in a name is doubled, per RFC 4180', () async {
    await loggedSession(exerciseName: 'The "widowmaker"');

    final file = await exporter().build();

    expect(file.contents, contains('"The ""widowmaker"""'));
  });

  test('a deleted routine still names itself in history', () async {
    await loggedSession();
    // A one-shot read, not `watchRoutines().first` — awaiting a drift stream
    // in a test body waits on a timer nothing here will fire.
    final session = (await workouts.exportCompletedSets()).first.session;
    await routines.delete(session.routineId!);

    final file = await exporter().build();

    // Soft deletes are what make this work: the row survives, so the export
    // does not suddenly lose the name of every session from last year.
    expect(rowsOf(file.contents)[1], contains('Push'));
  });
}
