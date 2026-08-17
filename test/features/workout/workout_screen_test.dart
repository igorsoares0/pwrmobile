import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/theme/theme.dart';
import 'package:pwrmobile/core/catalog/catalog_provider.dart';
import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/workout/rest_pill.dart';
import 'package:pwrmobile/features/workout/rest_timer.dart';
import 'package:pwrmobile/features/workout/set_row.dart';
import 'package:pwrmobile/features/workout/workout_launcher.dart';
import 'package:pwrmobile/features/workout/workout_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';
import 'package:pwrmobile/shared/utils/formatting.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('formatClock', () {
    test('pads minutes and seconds', () {
      expect(formatClock(const Duration(seconds: 7)), '00:07');
      expect(formatClock(const Duration(minutes: 42, seconds: 7)), '42:07');
    });

    test('grows an hours field only when needed', () {
      expect(formatClock(const Duration(minutes: 59)), '59:00');
      expect(formatClock(const Duration(hours: 1, seconds: 5)), '1:00:05');
    });

    test('clamps negatives to zero', () {
      // A finished rest reads 00:00, never -00:01.
      expect(formatClock(const Duration(seconds: -5)), '00:00');
    });
  });

  group('parseWeight', () {
    test('accepts both decimal separators', () {
      // A Brazilian keyboard produces a comma, an American one a dot.
      expect(parseWeight('22,5'), 22.5);
      expect(parseWeight('22.5'), 22.5);
      expect(parseWeight('80'), 80);
    });

    test('treats blank and junk as no value', () {
      expect(parseWeight(''), isNull);
      expect(parseWeight('   '), isNull);
      expect(parseWeight('abc'), isNull);
    });
  });

  group('rest timer', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    RestTimerNotifier notifier() => container.read(restTimerProvider.notifier);
    RestTimerState state() => container.read(restTimerProvider);

    test('is inactive until started', () {
      expect(state().isActive, isFalse);
      expect(state().running, isFalse);
    });

    test('starting sets the full duration and runs', () {
      notifier().start(90);

      expect(state().remaining, const Duration(seconds: 90));
      expect(state().total, const Duration(seconds: 90));
      expect(state().running, isTrue);
      expect(state().progress, 0);

      notifier().skip();
    });

    test('pause stops it where it is, resume picks it up', () {
      notifier().start(90);
      notifier().pause();
      expect(state().running, isFalse);
      expect(state().remaining, const Duration(seconds: 90));

      notifier().resume();
      expect(state().running, isTrue);

      notifier().skip();
    });

    test('extending adds to both remaining and total', () {
      notifier().start(60);
      notifier().pause();
      notifier().extend(30);

      expect(state().remaining, const Duration(seconds: 90));
      expect(state().total, const Duration(seconds: 90));

      notifier().skip();
    });

    test('skipping clears it entirely', () {
      notifier().start(90);
      notifier().skip();

      expect(state().isActive, isFalse);
    });

    test('resume does nothing when nothing was started', () {
      notifier().resume();
      expect(state().isActive, isFalse);
    });
  });

  group('screen', () {
    late AppDatabase db;
    late ExerciseCatalog catalog;
    late RoutineRepository routines;
    late ExerciseRepository exercises;
    late WorkoutRepository workouts;
    late WorkoutSession session;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      catalog = ExerciseCatalog.parse(
        File('assets/catalog/exercises.json').readAsStringSync(),
      );
      routines = RoutineRepository(db);
      exercises = ExerciseRepository(db, catalog);
      workouts = WorkoutRepository(db);

      final routine = await routines.create(name: 'Push A');
      final bench = await exercises.create(
        name: 'Supino',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      final fly = await exercises.create(
        name: 'Crucifixo',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.dumbbell,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: bench.id,
        targetSets: 2,
        restSeconds: 90,
      );
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: fly.id,
        targetSets: 2,
        restSeconds: 60,
      );

      session = await workouts.startFromRoutine(routine.id);
    });

    tearDown(() async {
      await db.close();
    });

    /// Flushes drift's cache timers and the rest ticker inside the body — the
    /// binding checks for pending timers before package:test teardowns run.
    void testWorkout(
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

    Future<void> pumpWorkout(
      WidgetTester tester, {
      VoidCallback? onFinished,
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
            home: WorkoutScreen(sessionId: session.id, onFinished: onFinished),
          ),
        ),
      );
      await settle(tester);
    }

    Finder checkButtons() => find.byIcon(Icons.check);

    testWorkout('shows the first exercise and its planned sets', (
      tester,
    ) async {
      await pumpWorkout(tester);

      expect(find.text('Supino'), findsOneWidget);
      expect(find.textContaining('EM ANDAMENTO · EX. 1 DE 2'), findsOneWidget);
      // Two planned sets, so two checkmarks.
      expect(checkButtons(), findsNWidgets(2));
      // And a hint at what comes after.
      expect(find.textContaining('Crucifixo'), findsOneWidget);
    });

    testWorkout('a first-time exercise says so instead of faking a number', (
      tester,
    ) async {
      await pumpWorkout(tester);

      expect(find.text('PRIMEIRA VEZ'), findsOneWidget);
    });

    testWorkout('checking a set off records the typed load', (tester) async {
      await pumpWorkout(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '80');
      await tester.enterText(fields.at(1), '8');
      await settle(tester);

      await tester.tap(checkButtons().first);
      await settle(tester);

      // Asserted through the UI: awaiting a drift stream here would deadlock.
      // The rest card only appears once a set has been checked off.
      expect(find.text('DESCANSO'), findsOneWidget);
      expect(find.text('01:30'), findsOneWidget);
    });

    testWorkout('checking a set off confirms in the hand', (tester) async {
      // The set row is the one gesture the product is built around, and a
      // haptic is the only confirmation that does not ask the user to look.
      // Easy to drop in a refactor and impossible to notice in a widget test
      // unless something asserts it, so: assert it.
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpWorkout(tester);

      await tester.tap(checkButtons().first);
      await settle(tester);

      expect(haptics, ['HapticFeedbackType.selectionClick']);

      // Un-checking is a correction, not an achievement: it stays silent.
      haptics.clear();
      await tester.tap(checkButtons().first);
      await settle(tester);

      expect(haptics, isEmpty);
    });

    testWorkout('the rest countdown ticks down', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(checkButtons().first);
      await settle(tester);
      expect(find.text('01:30'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('01:29'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('01:27'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await settle(tester);
    });

    testWorkout('rest can be paused and extended', (tester) async {
      await pumpWorkout(tester);

      await tester.tap(checkButtons().first);
      await settle(tester);
      expect(find.text('DESCANSO'), findsOneWidget);

      // Pausing is the ring itself, not a third button: the countdown is a
      // 56dp target that was already there, and dropping the button is what
      // keeps +30s and Pular in reach without a Wrap.
      await tester.tap(find.byType(CircularProgressIndicator));
      await settle(tester);
      expect(find.text('PAUSADO'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      // Paused means paused: the clock does not move.
      expect(find.text('01:30'), findsOneWidget);

      await tester.tap(find.text('+30s'));
      await settle(tester);
      expect(find.text('02:00'), findsOneWidget);

      await tester.tap(find.byType(CircularProgressIndicator));
      await settle(tester);
      expect(find.text('DESCANSO'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await settle(tester);
    });

    testWorkout('the rest pill floats instead of resizing the exercise', (
      tester,
    ) async {
      await pumpWorkout(tester);

      // The regression this guards: the countdown used to be a child of the
      // screen's Column, so starting a rest took its height out of the page
      // above it. The page got shorter at the exact moment the thumb came off
      // the checkmark — and once the list is scrolled near the end, which is
      // where you are when checking off the last set, a shorter viewport drags
      // the content back down with it.
      final before = tester.getRect(find.byType(PageView));

      await tester.tap(checkButtons().first);
      await settle(tester);
      expect(find.text('DESCANSO'), findsOneWidget);

      // States the premise, so the assertion below cannot pass by the pill
      // being empty: it is a real block of height, it just is not taken out of
      // the page's.
      expect(tester.getSize(find.byType(RestPill)).height, greaterThan(40));
      expect(tester.getRect(find.byType(PageView)), before);

      await tester.tap(find.text('Pular'));
      await settle(tester);

      expect(find.text('DESCANSO'), findsNothing);
      expect(tester.getRect(find.byType(PageView)), before);
    });

    testWorkout('un-checking a set is possible after a mis-tap', (
      tester,
    ) async {
      await pumpWorkout(tester);

      await tester.tap(checkButtons().first);
      await settle(tester);
      await tester.tap(find.text('Pular'));
      await settle(tester);

      // Tapping the same set again clears it, so no rest restarts.
      await tester.tap(checkButtons().first);
      await settle(tester);

      expect(find.text('DESCANSO'), findsNothing);
    });

    testWorkout('adding a set appends a row', (tester) async {
      await pumpWorkout(tester);
      expect(checkButtons(), findsNWidgets(2));

      await tester.tap(find.text('Adicionar série'));
      await settle(tester);

      expect(checkButtons(), findsNWidgets(3));
    });

    testWorkout('finishing asks first and reports how much was done', (
      tester,
    ) async {
      var finished = false;
      await pumpWorkout(tester, onFinished: () => finished = true);

      await tester.tap(checkButtons().first);
      await settle(tester);
      await tester.tap(find.text('Pular'));
      await settle(tester);

      await tester.tap(find.text('Finalizar treino'));
      await settle(tester);

      expect(find.textContaining('1 de 4 séries marcadas'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await settle(tester);
      expect(finished, isFalse);

      await tester.tap(find.text('Finalizar treino'));
      await settle(tester);
      await tester.tap(find.text('Finalizar'));
      await settle(tester);

      expect(finished, isTrue);
      // Once finished it is no longer the active session.
      expect(find.text('Nenhum treino em andamento.'), findsOneWidget);
    });
  });

  group('starting a workout', () {
    late AppDatabase db;
    late RoutineRepository routines;
    late WorkoutRepository workouts;
    late WorkoutLauncher launcher;
    late Routine routine;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      routines = RoutineRepository(db);
      workouts = WorkoutRepository(db);
      launcher = WorkoutLauncher(workouts);
      routine = await routines.create(name: 'Push A');
    });

    tearDown(() async {
      await db.close();
    });

    test('starts a new session when nothing is running', () async {
      final session = await launcher.startOrResume(routine.id);

      expect(session.routineId, routine.id);
      expect(session.finishedAt, isNull);
    });

    test('resumes the open session rather than throwing', () async {
      final first = await launcher.startOrResume(routine.id);
      final second = await launcher.startOrResume(routine.id);

      // Tapping a routine mid-workout means "take me back", not "error".
      expect(second.id, first.id);
    });
  });
}
