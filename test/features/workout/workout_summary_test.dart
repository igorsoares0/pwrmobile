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
import 'package:pwrmobile/features/workout/workout_summary_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late RoutineRepository routines;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;
  late Routine routine;
  late Exercise bench;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    routines = RoutineRepository(db);
    exercises = ExerciseRepository(db, catalog);
    workouts = WorkoutRepository(db);

    routine = await routines.create(name: 'Push A');
    bench = await exercises.create(
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

  /// Runs a session on the routine, checking off the given (weight, reps)
  /// pairs, and returns the finished session id.
  ///
  /// Must be driven through [WidgetTester.runAsync] when called from inside a
  /// widget test: `startFromRoutine` opens a drift transaction, and a
  /// transaction never completes under the fake clock a widget test installs.
  Future<String> runSession(List<(double, int)> sets) async {
    final session = await workouts.startFromRoutine(routine.id);
    final details = await workouts.sessionExercises(session.id);
    final rows = details.single.sets;

    for (var i = 0; i < sets.length; i++) {
      await workouts.completeSet(
        rows[i].id,
        weight: sets[i].$1,
        reps: sets[i].$2,
      );
    }

    await workouts.finish(session.id);
    return session.id;
  }

  void testSummary(
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

  /// Real-async escape hatch for the database work a test needs before
  /// pumping. See [runSession].
  Future<T> realAsync<T>(WidgetTester tester, Future<T> Function() body) async {
    final result = await tester.runAsync(body);
    return result as T;
  }

  Future<void> pumpSummary(
    WidgetTester tester,
    String sessionId, {
    VoidCallback? onClose,
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
          home: WorkoutSummaryScreen(sessionId: sessionId, onClose: onClose),
        ),
      ),
    );
    await settle(tester);
  }

  group('totals', () {
    testSummary('names the routine and sums the volume', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8), (85, 6)]));
      await pumpSummary(tester, id);

      expect(find.text('Push A registrado.'), findsOneWidget);
      // 80×8 + 85×6 = 1150 kg, exact rather than rounded to tonnes. The
      // headline is a Text.rich, so the value and unit render as one string.
      expect(find.textContaining('1.150'), findsOneWidget);
      expect(find.textContaining('VOLUME TOTAL'), findsNothing);
      expect(find.textContaining('volume total'), findsOneWidget);
    });

    testSummary('counts sets and exercises actually performed', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, id);

      // One of the two planned sets was checked off, on one exercise.
      expect(find.text('1'), findsWidgets);
      expect(find.text('SÉRIES'), findsOneWidget);
      expect(find.text('EXERCÍCIOS'), findsOneWidget);
    });

    testSummary('lists the best set per exercise', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8), (85, 6)]));
      await pumpSummary(tester, id);

      expect(find.text('SEUS MELHORES DE HOJE'), findsOneWidget);
      expect(find.text('Supino'), findsOneWidget);
      // 85 beats 80 on load, so it is the one shown.
      expect(find.text('85kg × 6'), findsOneWidget);
    });
  });

  group('comparison with last time', () {
    testSummary('a first session on a routine says so', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, id);

      // No invented +0%: there is nothing to compare against.
      expect(find.textContaining('primeira vez nesta rotina'), findsOneWidget);
    });

    testSummary('a heavier session reports a signed gain', (tester) async {
      await realAsync(tester, () => runSession([(80, 10)])); // 800 kg
      final second = await realAsync(
        tester,
        () => runSession([(80, 12)]),
      ); // 960 kg, +20%
      await pumpSummary(tester, second);

      expect(find.textContaining('+20%'), findsOneWidget);
      expect(find.textContaining('da última vez'), findsOneWidget);
    });

    testSummary('a lighter session reports a loss', (tester) async {
      await realAsync(tester, () => runSession([(100, 10)])); // 1000 kg
      final second = await realAsync(
        tester,
        () => runSession([(80, 10)]),
      ); // 800 kg, −20%
      await pumpSummary(tester, second);

      expect(find.textContaining('−20%'), findsOneWidget);
    });

    testSummary('a previous session with no volume is not compared against', (
      tester,
    ) async {
      // Started and finished without checking anything off.
      final empty = await realAsync(
        tester,
        () => workouts.startFromRoutine(routine.id),
      );
      await realAsync(tester, () => workouts.finish(empty.id));

      final second = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, second);

      // Dividing by zero would have claimed an infinite improvement.
      expect(find.textContaining('primeira vez nesta rotina'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  group('edge cases', () {
    testSummary('a session with nothing checked off says so', (tester) async {
      final session = await realAsync(
        tester,
        () => workouts.startFromRoutine(routine.id),
      );
      await realAsync(tester, () => workouts.finish(session.id));
      await pumpSummary(tester, session.id);

      expect(find.text('Nada foi marcado.'), findsOneWidget);
      expect(find.text('SEUS MELHORES DE HOJE'), findsNothing);
    });

    testSummary('a bodyweight set reports reps rather than 0kg', (
      tester,
    ) async {
      final session = await realAsync(
        tester,
        () => workouts.startFromRoutine(routine.id),
      );
      final details = await realAsync(
        tester,
        () => workouts.sessionExercises(session.id),
      );
      await realAsync(
        tester,
        () => workouts.completeSet(details.single.sets.first.id, reps: 12),
      );
      await realAsync(tester, () => workouts.finish(session.id));

      await pumpSummary(tester, session.id);

      expect(find.text('12 reps'), findsOneWidget);
    });

    testSummary('an unknown session does not crash the screen', (tester) async {
      await pumpSummary(tester, 'no-such-session');

      expect(find.text('Esse treino não existe mais.'), findsOneWidget);
    });

    testSummary('closing calls back', (tester) async {
      var closed = false;
      final id = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, id, onClose: () => closed = true);

      await tester.tap(find.text('Concluir'));
      await settle(tester);

      expect(closed, isTrue);
    });
  });
}
