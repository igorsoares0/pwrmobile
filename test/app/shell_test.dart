import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/app.dart';
import 'package:pwrmobile/core/catalog/catalog_provider.dart';
import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/app/shell/pwr_shell.dart';
import 'package:pwrmobile/core/database/exercise_seeder.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/workout/workout_screen.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    await ExerciseSeeder(db).seed(catalog);
  });

  tearDown(() async {
    await db.close();
  });

  /// Flushes drift's cache timers inside the body — the binding checks for
  /// pending timers before package:test teardowns run.
  void testShell(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }

  /// Boots the whole app, router included, so the tabs are exercised the way
  /// they actually ship rather than through a hand-built harness.
  ///
  /// Assertions are in English: `PwrApp` resolves the platform locale, and the
  /// test environment reports `en`. Portuguese rendering is covered by the
  /// per-screen tests, which pin the locale explicitly.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWithValue(catalog),
        ],
        child: const PwrApp(),
      ),
    );
    await settle(tester);
  }

  testShell('opens on the training tab', (tester) async {
    await pumpApp(tester);

    expect(find.text('PWR'), findsOneWidget);
    expect(find.text('TRAINING'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testShell('switches to history and back', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('HISTORY'));
    await settle(tester);
    expect(find.text('No workouts yet.'), findsOneWidget);

    await tester.tap(find.text('TRAINING'));
    await settle(tester);
    expect(find.text('Good session.'), findsOneWidget);
  });

  testShell('the body tab explains itself before there is any data', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('BODY'));
    await settle(tester);

    expect(find.text('No weigh-ins yet.'), findsOneWidget);
    // What is locked is on screen and says so, rather than being hidden.
    expect(find.text('Chest'), findsOneWidget);
  });

  testShell('the profile tab reaches the settings that exist', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('PROFILE'));
    await settle(tester);

    expect(find.text('Weight unit'), findsOneWidget);
  });

  testShell('the weekly card jumps to the history tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('WORKOUTS\nTHIS WEEK'));
    await settle(tester);

    // A tab switch, not a push: no back arrow appears over the tab bar.
    expect(find.text('History'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testShell('the centre button starts a workout that can be filled in', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Start a workout'));
    await settle(tester);

    // A freestyle session has no routine behind it, so it must offer a way to
    // add exercises or it is a dead end.
    expect(find.text('This workout has no exercises.'), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  group('active session bar', () {
    /// Backdates the open session, to reach the state a phone that spent the
    /// night in a gym bag wakes up in.
    Future<void> backdate(String id, Duration by) {
      return (db.update(db.workoutSessions)
        ..where((tbl) => tbl.id.equals(id))).write(
        WorkoutSessionsCompanion(
          startedAt: Value(DateTime.now().toUtc().subtract(by)),
        ),
      );
    }

    testShell('stays out of the way when nothing is running', (tester) async {
      await pumpApp(tester);

      expect(find.textContaining('IN PROGRESS'), findsNothing);
    });

    testShell('follows the user across tabs', (tester) async {
      await WorkoutRepository(db).startEmpty();
      await pumpApp(tester);

      // The point of moving this out of the home screen: a session is just as
      // real from the body tab, and so is the rest countdown that keeps
      // running while the user is over there.
      expect(find.text('Freestyle workout'), findsOneWidget);
      expect(find.textContaining('IN PROGRESS'), findsOneWidget);

      await tester.tap(find.text('BODY'));
      await settle(tester);

      expect(find.text('Freestyle workout'), findsOneWidget);
      expect(find.textContaining('IN PROGRESS'), findsOneWidget);
    });

    testShell('goes quiet once the session is finished', (tester) async {
      final workouts = WorkoutRepository(db);
      final session = await workouts.startEmpty();
      await workouts.finish(session.id);

      await pumpApp(tester);

      expect(find.textContaining('IN PROGRESS'), findsNothing);
    });

    testShell('a session left open reports when, not for how long', (
      tester,
    ) async {
      final session = await WorkoutRepository(db).startEmpty();
      await backdate(session.id, const Duration(hours: 14));

      await pumpApp(tester);

      // `elapsedProvider` recomputes from `startedAt` precisely so it survives
      // a process restart, which means it would report 14:00:00 with total
      // confidence. Nobody rests for fourteen hours; the bar says when the
      // session was opened instead of pretending it is under way.
      expect(find.textContaining('OPEN SINCE'), findsOneWidget);
      expect(find.textContaining('IN PROGRESS'), findsNothing);
    });
  });

  testShell('the workout is pushed over the shell, not inside a tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Start a workout'));
    await settle(tester);
    expect(find.text('Finish workout'), findsOneWidget);

    // Asserted by position in the tree rather than by looking for the tab bar:
    // Flutter keeps routes below an opaque one mounted, so the bar stays
    // findable even though nothing paints it. Living outside the shell is the
    // property that actually decides whether a tab bar can appear over a
    // workout.
    expect(find.byType(WorkoutScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PwrShell),
        matching: find.byType(WorkoutScreen),
      ),
      findsNothing,
    );
  });
}
