import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/theme/theme.dart';
import 'package:pwrmobile/core/catalog/catalog_provider.dart';
import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/routines/routine_builder_providers.dart';
import 'package:pwrmobile/features/routines/routine_builder_screen.dart';
import 'package:pwrmobile/features/routines/routine_creation.dart';
import 'package:pwrmobile/features/routines/slot_editor_sheet.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

/// Bounded pumps — see `testBuilder` for why not `pumpAndSettle`.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('superset grouping', () {
    // Pure logic, no database — the rule is the part worth pinning down.
    List<int?> groups(int count, List<bool> chains) =>
        RoutineRepository.supersetGroupsFor(count, chains);

    test('no chains means every slot stands alone', () {
      expect(groups(3, [false, false, false]), [null, null, null]);
    });

    test('one chain pairs two adjacent slots', () {
      expect(groups(3, [true, false, false]), [0, 0, null]);
    });

    test('consecutive chains form a single run, not two pairs', () {
      // A three-movement giant set is one group, not two overlapping pairs.
      expect(groups(4, [true, true, false, false]), [0, 0, 0, null]);
    });

    test('separated chains get distinct groups', () {
      expect(groups(4, [true, false, true, false]), [0, 0, 1, 1]);
    });

    test('a chain on the last slot is ignored', () {
      expect(groups(2, [false, true]), [null, null]);
    });

    test('an empty routine produces nothing', () {
      expect(groups(0, const []), isEmpty);
    });
  });

  group('builder', () {
    late AppDatabase db;
    late ExerciseCatalog catalog;
    late RoutineRepository routines;
    late ExerciseRepository exercises;
    late Routine routine;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      catalog = ExerciseCatalog.parse(
        File('assets/catalog/exercises.json').readAsStringSync(),
      );
      routines = RoutineRepository(db);
      exercises = ExerciseRepository(db, catalog);
      routine = await routines.create(name: 'Push A');
    });

    tearDown(() async {
      await db.close();
    });

    /// Flushes drift's query-cache timers inside the body; the binding checks
    /// for pending timers before package:test teardowns run.
    void testBuilder(
      String description,
      Future<void> Function(WidgetTester) body,
    ) {
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
      });
    }

    Future<Exercise> addExercise(String name, {int sets = 3}) async {
      final exercise = await exercises.create(
        name: name,
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
        targetSets: sets,
      );
      return exercise;
    }

    Future<void> pumpBuilder(
      WidgetTester tester, {
      Future<Exercise?> Function()? onPickExercise,
      VoidCallback? onDone,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exerciseCatalogProvider.overrideWithValue(catalog),
          ],
          child: MaterialApp(
            theme: PwrTheme.dark,
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RoutineBuilderScreen(
              routineId: routine.id,
              onPickExercise: onPickExercise,
              onDone: onDone,
            ),
          ),
        ),
      );
      await settle(tester);
    }

    testBuilder('shows the routine name and its slots', (tester) async {
      await addExercise('Supino', sets: 4);
      await pumpBuilder(tester);

      expect(find.text('Push A'), findsOneWidget);
      expect(find.text('Supino'), findsOneWidget);
      expect(find.textContaining('4 SÉRIES'), findsOneWidget);
    });

    testBuilder('an empty routine explains what to add', (tester) async {
      await pumpBuilder(tester);

      expect(find.text('Nenhum exercício ainda.'), findsOneWidget);
    });

    testBuilder('renaming writes through on every keystroke', (tester) async {
      await pumpBuilder(tester);

      await tester.enterText(find.byType(TextField).first, 'Pull B');
      await settle(tester);

      // Asserted through the rebuilt UI: awaiting a drift stream inside a
      // widget test deadlocks on a timer only a pump can fire.
      expect(find.text('Pull B'), findsOneWidget);
    });

    testBuilder('picking an exercise appends it', (tester) async {
      final press = await exercises.create(
        name: 'Leg press',
        muscleGroup: MuscleGroup.quads,
        equipment: Equipment.machine,
      );

      await pumpBuilder(tester, onPickExercise: () async => press);
      await tester.tap(find.text('Adicionar exercício'));
      await settle(tester);

      expect(find.text('Leg press'), findsOneWidget);
    });

    testBuilder('a cancelled pick adds nothing', (tester) async {
      await pumpBuilder(tester, onPickExercise: () async => null);
      await tester.tap(find.text('Adicionar exercício'));
      await settle(tester);

      expect(find.text('Nenhum exercício ainda.'), findsOneWidget);
    });

    testBuilder('the slot editor changes sets and rest', (tester) async {
      await addExercise('Supino', sets: 3);
      await pumpBuilder(tester);

      await tester.tap(find.text('Supino'));
      await settle(tester);
      // The sheet titles itself with the exercise name; `Séries` is the first
      // control inside it.
      expect(find.text('SÉRIES'), findsOneWidget);

      // Scoped to the sheet: the builder behind it also has an add icon, and
      // an unscoped `.first` would reach for the one under the modal barrier.
      await tester.tap(
        find
            .descendant(
              of: find.byType(SlotEditorSheet),
              matching: find.byIcon(Icons.add),
            )
            .first,
      );
      await settle(tester);
      await tester.tap(find.text('120s'));
      await settle(tester);
      // The builder's own bottom button carries the same label, so this one
      // has to be scoped to the sheet too.
      await tester.tap(
        find.descendant(
          of: find.byType(SlotEditorSheet),
          matching: find.text('Concluir'),
        ),
      );
      await settle(tester);

      expect(find.textContaining('4 SÉRIES · DESC. 120S'), findsOneWidget);
    });

    testBuilder('removing a slot empties the routine', (tester) async {
      await addExercise('Supino');
      await pumpBuilder(tester);

      await tester.tap(find.text('Supino'));
      await settle(tester);
      await tester.tap(find.text('Remover da rotina'));
      await settle(tester);

      expect(find.text('Nenhum exercício ainda.'), findsOneWidget);
    });
  });

  group('abandoned routines', () {
    late AppDatabase db;
    late RoutineRepository routines;
    late ExerciseCatalog catalog;
    late RoutineCreation creation;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      catalog = ExerciseCatalog.parse(
        File('assets/catalog/exercises.json').readAsStringSync(),
      );
      routines = RoutineRepository(db);
      creation = RoutineCreation(routines);
    });

    tearDown(() async {
      await db.close();
    });

    test('an untouched routine is discarded on leaving', () async {
      final routine = await creation.create('Nova rotina');

      expect(
        await creation.discardIfUntouched(routine.id, 'Nova rotina'),
        isTrue,
      );
      expect(await routines.watchRoutines().first, isEmpty);
    });

    test('a renamed routine is kept', () async {
      final routine = await creation.create('Nova rotina');
      await routines.update(routine.id, name: 'Push A');

      expect(
        await creation.discardIfUntouched(routine.id, 'Nova rotina'),
        isFalse,
      );
      expect(await routines.watchRoutines().first, hasLength(1));
    });

    test('a routine with an exercise is kept', () async {
      final routine = await creation.create('Nova rotina');
      final exercise = await ExerciseRepository(db, catalog).create(
        name: 'Supino',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
      );

      expect(
        await creation.discardIfUntouched(routine.id, 'Nova rotina'),
        isFalse,
      );
    });

    test('a routine given only a focus is kept', () async {
      final routine = await creation.create('Nova rotina');
      await routines.update(routine.id, focus: 'Peito');

      expect(
        await creation.discardIfUntouched(routine.id, 'Nova rotina'),
        isFalse,
      );
    });
  });

  group('chain flags', () {
    test('are derived from shared superset groups', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final catalog = ExerciseCatalog.parse(
        File('assets/catalog/exercises.json').readAsStringSync(),
      );
      final routines = RoutineRepository(db);
      final exercises = ExerciseRepository(db, catalog);
      final routine = await routines.create(name: 'Push A');

      for (final name in ['A', 'B', 'C']) {
        final exercise = await exercises.create(
          name: name,
          muscleGroup: MuscleGroup.chest,
          equipment: Equipment.barbell,
        );
        await routines.addExercise(
          routineId: routine.id,
          exerciseId: exercise.id,
        );
      }

      await routines.setSupersetChains(routine.id, [true, false, false]);
      final slots = await routines.watchExercises(routine.id).first;

      expect(chainFlagsOf(slots), [true, false, false]);
      expect(slots[0].isSuperset, isTrue);
      expect(slots[2].isSuperset, isFalse);

      await db.close();
    });
  });
}
