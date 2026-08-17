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
import 'package:pwrmobile/features/home/home_screen.dart';
import 'package:pwrmobile/features/subscription/entitlement.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

/// Bounded pumps instead of `pumpAndSettle`.
///
/// The screen is driven by drift streams, which deliver over several microtask
/// turns. `pumpAndSettle` keeps pumping until the frame scheduler goes quiet,
/// which on a stream-backed screen means waiting out its ten minute timeout
/// rather than failing fast.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  late AppDatabase db;
  late RoutineRepository routines;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;
  late ExerciseCatalog catalog;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    routines = RoutineRepository(db);
    exercises = ExerciseRepository(db, catalog);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// A widget test that flushes drift's cache timers before it ends.
  ///
  /// Drift keeps a query's cache alive for one event-loop turn after its last
  /// listener goes away, using a timer. The binding asserts no timers are
  /// pending *before* package:test teardowns run, so the flush cannot live in
  /// `tearDown`.
  ///
  /// Those same timers are why `pumpAndSettle` never goes quiet here: the
  /// frame scheduler keeps being handed new work.
  void testHome(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);

      // Unmount, then pump. Disposing the ProviderScope cancels the drift
      // stream subscriptions, and each one schedules a `Timer.run` to expire
      // its query cache. Pumping is what makes those fire under FakeAsync, and
      // the binding asserts no timer is left pending.
      //
      // Do NOT `await db.close()` here instead: `close()` waits on exactly
      // these timers, and awaiting them without pumping deadlocks the test.
      // The database is closed in `tearDown`, once nothing is pending.
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    Locale locale = const Locale('pt'),
    Entitlement entitlement = Entitlement.free,
    void Function(String routineId)? onStartRoutine,
    void Function(String routineId)? onEditRoutine,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWithValue(catalog),
          entitlementProvider.overrideWithValue(entitlement),
        ],
        child: MaterialApp(
          theme: PwrTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(
            onStartRoutine: onStartRoutine,
            onEditRoutine: onEditRoutine,
          ),
        ),
      ),
    );

    await settle(tester);
  }

  group('empty state', () {
    testHome('a fresh install is told what a routine is for', (tester) async {
      await pumpHome(tester);

      // The first thing every new user sees. An empty list with no explanation
      // would leave them with nothing to tap.
      expect(find.text('Nenhuma rotina ainda.'), findsOneWidget);
      expect(find.text('Criar rotina'), findsOneWidget);
    });

    testHome('weekly stats read zero rather than blank', (tester) async {
      await pumpHome(tester);

      expect(find.text('0'), findsWidgets);
      expect(find.text('TREINOS\nNA SEMANA'), findsOneWidget);
    });
  });

  group('routines', () {
    testHome('every routine renders as the same row', (tester) async {
      final push = await routines.create(name: 'Push A', focus: 'Peito');
      await routines.create(name: 'Pull B');

      final bench = await exercises.create(
        name: 'Supino',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      await routines.addExercise(
        routineId: push.id,
        exerciseId: bench.id,
        targetSets: 4,
        restSeconds: 90,
      );

      await pumpHome(tester);

      expect(find.text('Push A'), findsOneWidget);
      expect(find.text('Pull B'), findsOneWidget);

      // Focus reads inside the row subtitle rather than as a line of its own.
      // 4 sets x (90s rest + 30s work) = 480s = 8 min.
      expect(find.text('PEITO · 1 EXERCÍCIO · ~8 MIN'), findsOneWidget);
    });

    testHome('every routine can be edited, the first one included', (
      tester,
    ) async {
      // The regression this guards: while the first routine rendered as an
      // accent card it had no edit affordance, and the builder was reachable
      // from nowhere else — so routine one could never be edited or deleted.
      final push = await routines.create(name: 'Push A');
      await routines.create(name: 'Pull B');
      String? edited;

      await pumpHome(tester, onEditRoutine: (id) => edited = id);

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pump();

      expect(edited, push.id);
    });

    testHome('tapping a routine reports which one', (tester) async {
      final push = await routines.create(name: 'Push A');
      String? started;

      await pumpHome(tester, onStartRoutine: (id) => started = id);

      await tester.tap(find.text('Push A'));
      await tester.pump();

      expect(started, push.id);
    });

    testHome('the free counter reflects the plan limit', (tester) async {
      await routines.create(name: 'A');
      await routines.create(name: 'B');

      await pumpHome(tester);

      expect(find.text('2/3 no free'), findsOneWidget);
    });

    testHome('PRO shows a plain count instead of a limit', (tester) async {
      await routines.create(name: 'A');

      await pumpHome(tester, entitlement: Entitlement.pro);

      expect(find.text('1 rotinas'), findsOneWidget);
      expect(find.textContaining('no free'), findsNothing);
    });

    testHome('the free plan locks the new-routine row at the limit', (
      tester,
    ) async {
      for (final name in ['A', 'B', 'C']) {
        await routines.create(name: name);
      }

      await pumpHome(tester);

      expect(find.text('LIMITE DO PLANO FREE ATINGIDO'), findsOneWidget);
    });

    testHome('below the limit the new-routine row is not locked', (
      tester,
    ) async {
      await routines.create(name: 'A');

      await pumpHome(tester);

      expect(find.text('LIMITE DO PLANO FREE ATINGIDO'), findsNothing);
      expect(find.text('Nova rotina'), findsOneWidget);
    });
  });

  group('resume banner', () {
    testHome('is absent with no workout in progress', (tester) async {
      await pumpHome(tester);

      expect(find.text('Treino em andamento'), findsNothing);
    });

    testHome('surfaces a session left open', (tester) async {
      await workouts.startEmpty();

      await pumpHome(tester);

      // A session left unfinished means the user walked away mid-workout;
      // burying that behind navigation would hide the crash recovery.
      expect(find.text('Treino em andamento'), findsOneWidget);
    });

    testHome('disappears once the session is finished', (tester) async {
      final session = await workouts.startEmpty();
      await workouts.finish(session.id);

      await pumpHome(tester);

      expect(find.text('Treino em andamento'), findsNothing);
    });
  });

  group('localisation', () {
    testHome('renders in English', (tester) async {
      await pumpHome(tester, locale: const Locale('en'));

      expect(find.text('Good session.'), findsOneWidget);
      expect(find.text('No routines yet.'), findsOneWidget);
      expect(find.text('Exercise library'), findsOneWidget);
    });

    testHome('renders in Portuguese', (tester) async {
      await pumpHome(tester, locale: const Locale('pt'));

      expect(find.text('Bom treino.'), findsOneWidget);
      expect(find.text('Biblioteca de exercícios'), findsOneWidget);
    });

    testHome('an unsupported locale falls back to English', (tester) async {
      await pumpHome(tester, locale: const Locale('ja'));

      expect(find.text('Good session.'), findsOneWidget);
    });
  });
}
