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
import 'package:pwrmobile/core/database/exercise_seeder.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/features/onboarding/onboarding_screen.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late SettingsRepository settings;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    settings = SettingsRepository(db);
    await ExerciseSeeder(db).seed(catalog);
  });

  tearDown(() async {
    await db.close();
  });

  group('the seen flag', () {
    test('defaults to false on a fresh install', () async {
      expect(
        await settings.getFlag(SettingsRepository.onboardingSeen),
        isFalse,
      );
    });

    test('survives being written', () async {
      await settings.setFlag(SettingsRepository.onboardingSeen, value: true);

      expect(await settings.getFlag(SettingsRepository.onboardingSeen), isTrue);
    });

    test('writing twice does not fail on the primary key', () async {
      await settings.setFlag(SettingsRepository.onboardingSeen, value: true);
      await settings.setFlag(SettingsRepository.onboardingSeen, value: false);

      expect(
        await settings.getFlag(SettingsRepository.onboardingSeen),
        isFalse,
      );
    });

    test('an unknown key falls back to the supplied default', () async {
      expect(await settings.getFlag('nope'), isFalse);
      expect(await settings.getFlag('nope', orElse: true), isTrue);
    });
  });

  group('screen', () {
    /// Flushes drift's cache timers inside the body — the binding checks for
    /// pending timers before package:test teardowns run.
    void testOnboarding(
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

    /// Boots the real app so the routing decision is exercised, not mocked.
    ///
    /// Assertions are in English: `PwrApp` resolves the platform locale, which
    /// the test environment reports as `en`.
    Future<void> pumpApp(
      WidgetTester tester, {
      required bool showOnboarding,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exerciseCatalogProvider.overrideWithValue(catalog),
          ],
          child: PwrApp(showOnboarding: showOnboarding),
        ),
      );
      await settle(tester);
    }

    testOnboarding('a fresh install lands on the welcome screen', (
      tester,
    ) async {
      await pumpApp(tester, showOnboarding: true);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Pick a routine'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testOnboarding('it asks for nothing — no account, no sign-in', (
      tester,
    ) async {
      await pumpApp(tester, showOnboarding: true);

      // The prototype offers "I already have an account"; accounts do not
      // exist yet, and the spec only asks for one after the first workout.
      expect(find.textContaining('account'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testOnboarding('says plainly that it works offline', (tester) async {
      await pumpApp(tester, showOnboarding: true);

      expect(
        find.text('Works with no signal. Everything stays on this device.'),
        findsOneWidget,
      );
    });

    testOnboarding('starting moves to the home screen', (tester) async {
      await pumpApp(tester, showOnboarding: true);

      await tester.tap(find.text('Start'));
      await settle(tester);

      expect(find.text('Good session.'), findsOneWidget);
      expect(find.text('TRAINING'), findsOneWidget);
    });

    testOnboarding('starting records that it has been seen', (tester) async {
      await pumpApp(tester, showOnboarding: true);

      await tester.tap(find.text('Start'));
      await settle(tester);

      final seen = await tester.runAsync(
        () => settings.getFlag(SettingsRepository.onboardingSeen),
      );
      expect(seen, isTrue);
    });

    testOnboarding('a returning install skips it', (tester) async {
      await pumpApp(tester, showOnboarding: false);

      // By type, not by words: the home empty state repeats onboarding's
      // "three taps" promise, so a text match would find the wrong screen.
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Good session.'), findsOneWidget);
    });

    testOnboarding('there is no way back into it once started', (tester) async {
      await pumpApp(tester, showOnboarding: true);

      await tester.tap(find.text('Start'));
      await settle(tester);

      // `go`, not `push`: nothing is left on the stack to return to.
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });
}
