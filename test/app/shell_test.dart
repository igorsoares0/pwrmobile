import 'dart:io';

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

  testShell('the unbuilt tabs say so instead of showing an empty screen', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('BODY'));
    await settle(tester);
    expect(find.text('Measurements are not built yet.'), findsOneWidget);

    await tester.tap(find.text('PROFILE'));
    await settle(tester);
    expect(find.text('There is no account yet.'), findsOneWidget);
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

    await tester.tap(find.byIcon(Icons.add));
    await settle(tester);

    // A freestyle session has no routine behind it, so it must offer a way to
    // add exercises or it is a dead end.
    expect(find.text('This workout has no exercises.'), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });

  testShell('the workout is pushed over the shell, not inside a tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
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
