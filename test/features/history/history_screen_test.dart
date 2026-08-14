import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/theme/theme.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/history/history_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

import 'dart:io';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('groupByMonth', () {
    WorkoutSessionStats statsAt(DateTime startedAt, {String? name}) {
      return WorkoutSessionStats(
        session: WorkoutSession(
          id: startedAt.toIso8601String(),
          startedAt: startedAt,
          createdAt: startedAt,
          updatedAt: startedAt,
          version: 1,
        ),
        routineName: name,
        completedSetCount: 0,
        exerciseCount: 0,
        volume: 0,
      );
    }

    test('puts sessions from the same month together', () {
      final months = groupByMonth([
        statsAt(DateTime(2026, 8, 20)),
        statsAt(DateTime(2026, 8, 3)),
        statsAt(DateTime(2026, 7, 30)),
      ]);

      expect(months, hasLength(2));
      expect(months.first.sessions, hasLength(2));
      expect(months.last.sessions, hasLength(1));
    });

    test('keeps the newest-first order it was given', () {
      final months = groupByMonth([
        statsAt(DateTime(2026, 8, 20)),
        statsAt(DateTime(2026, 7, 30)),
        statsAt(DateTime(2026, 6, 1)),
      ]);

      expect(months.map((m) => m.month), [
        DateTime(2026, 8),
        DateTime(2026, 7),
        DateTime(2026, 6),
      ]);
    });

    test('groups by local month, not UTC', () {
      // A workout at 23:00 local on the last day of a month belongs to that
      // month even when its UTC timestamp has already rolled over.
      final lastDay = DateTime(2026, 7, 31, 23);
      final months = groupByMonth([statsAt(lastDay.toUtc())]);

      expect(months.single.month, DateTime(2026, 7));
    });

    test('an empty history groups into nothing', () {
      expect(groupByMonth(const []), isEmpty);
    });
  });

  group('screen', () {
    late AppDatabase db;
    late RoutineRepository routines;
    late ExerciseRepository exercises;
    late WorkoutRepository workouts;
    late Routine routine;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final catalog = ExerciseCatalog.parse(
        File('assets/catalog/exercises.json').readAsStringSync(),
      );
      routines = RoutineRepository(db);
      exercises = ExerciseRepository(db, catalog);
      workouts = WorkoutRepository(db);

      routine = await routines.create(name: 'Push A');
      final bench = await exercises.create(
        name: 'Supino',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: bench.id,
        targetSets: 2,
      );
    });

    tearDown(() async {
      await db.close();
    });

    void testHistory(
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

    /// Database work goes through `runAsync`: `startFromRoutine` opens a drift
    /// transaction, which never completes under a widget test's fake clock.
    Future<T> realAsync<T>(
      WidgetTester tester,
      Future<T> Function() body,
    ) async {
      return (await tester.runAsync(body)) as T;
    }

    Future<String> runSession(double weight, int reps) async {
      final session = await workouts.startFromRoutine(routine.id);
      final details = await workouts.sessionExercises(session.id);
      await workouts.completeSet(
        details.single.sets.first.id,
        weight: weight,
        reps: reps,
      );
      await workouts.finish(session.id);
      return session.id;
    }

    Future<void> pumpHistory(
      WidgetTester tester, {
      void Function(String)? onOpenSession,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: PwrTheme.dark,
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HistoryScreen(onOpenSession: onOpenSession),
          ),
        ),
      );
      await settle(tester);
    }

    testHistory('an empty history explains what will land there', (
      tester,
    ) async {
      await pumpHistory(tester);

      expect(find.text('Nenhum treino ainda.'), findsOneWidget);
    });

    testHistory('a finished session appears with its routine and volume', (
      tester,
    ) async {
      await realAsync(tester, () => runSession(80, 8));
      await pumpHistory(tester);

      expect(find.text('Push A'), findsOneWidget);
      expect(find.textContaining('640'), findsOneWidget);
      expect(find.textContaining('1 SÉRIE'), findsOneWidget);
    });

    testHistory('an unfinished session stays out of it', (tester) async {
      await realAsync(tester, () => workouts.startFromRoutine(routine.id));
      await pumpHistory(tester);

      // Only finished workouts are history; the one in progress is not.
      expect(find.text('Nenhum treino ainda.'), findsOneWidget);
    });

    testHistory('a session whose routine was deleted still renders', (
      tester,
    ) async {
      await realAsync(tester, () => runSession(80, 8));
      await realAsync(tester, () => routines.delete(routine.id));

      await pumpHistory(tester);

      // Deleting a routine must not erase the history of having trained it.
      expect(find.text('Push A'), findsOneWidget);
    });

    testHistory('tapping a session reports which one', (tester) async {
      final id = await realAsync(tester, () => runSession(80, 8));
      String? opened;

      await pumpHistory(tester, onOpenSession: (value) => opened = value);
      await tester.tap(find.text('Push A'));
      await settle(tester);

      expect(opened, id);
    });
  });
}
