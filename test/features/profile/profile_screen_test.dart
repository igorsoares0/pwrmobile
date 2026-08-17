import 'dart:io';
import 'dart:typed_data';

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
import 'package:pwrmobile/core/settings/preferences.dart';
import 'package:pwrmobile/features/profile/profile_screen.dart';
import 'package:pwrmobile/features/sharing/share_service.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

/// Records what would have been handed to the system share sheet.
class _RecordingShareService implements ShareService {
  String? contents;
  String? fileName;
  String? mimeType;
  int calls = 0;

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  }) async {}

  @override
  Future<void> shareText(
    String contents, {
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    calls++;
    this.contents = contents;
    this.fileName = fileName;
    this.mimeType = mimeType;
  }
}

/// Bounded pumps instead of `pumpAndSettle`, as everywhere else in this suite.
///
/// Long enough to outlast a modal bottom sheet's 250ms entrance: a tap on a tag
/// that is still sliding up misses it, and `tap` only *warns* about that before
/// carrying on to fail the assertion further down.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late SettingsRepository settings;
  late _RecordingShareService share;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    settings = SettingsRepository(db);
    share = _RecordingShareService();
  });

  tearDown(() async {
    await db.close();
  });

  /// A widget test that flushes drift's cache timers before it ends.
  ///
  /// See `home_screen_test.dart` for why this cannot live in `tearDown`.
  void testProfile(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exerciseCatalogProvider.overrideWithValue(catalog),
        shareServiceProvider.overrideWithValue(share),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PwrTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  testProfile('the header says what is true: a device, on the free plan', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('This device'), findsOneWidget);
    expect(find.text('FREE PLAN'), findsOneWidget);
    // No name, no gym, no subscription card — none of them have data behind
    // them until phases 2 and 4.
    expect(find.textContaining('PRO'), findsNothing);
  });

  testProfile('switching the unit persists it and relabels the row', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('KG'), findsOneWidget);

    await tester.tap(find.text('Weight unit'));
    await settle(tester);
    await tester.tap(find.text('LB'));
    await settle(tester);

    expect(find.text('LB'), findsOneWidget);
    expect(
      await settings.getString(SettingsRepository.weightUnit),
      WeightUnit.lb.name,
    );
  });

  testProfile('the default rest is written through', (tester) async {
    await pumpProfile(tester);

    expect(find.text('90S'), findsOneWidget);

    await tester.tap(find.text('Default rest'));
    await settle(tester);
    await tester.tap(find.text('120S'));
    await settle(tester);

    expect(find.text('120S'), findsOneWidget);
    expect(
      await settings.getInt(SettingsRepository.defaultRestSeconds),
      120,
    );
  });

  testProfile('the timer alert toggles off', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byType(Switch));
    await settle(tester);

    expect(
      await settings.getFlag(SettingsRepository.timerSound, orElse: true),
      isFalse,
    );
  });

  testProfile('exporting with nothing logged says so instead of sharing', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Export training log (CSV)'));
    await settle(tester);

    expect(share.calls, 0);
    expect(find.text('No finished workouts to export yet.'), findsOneWidget);
  });

  testProfile('a finished workout is shared as a csv file', (tester) async {
    // The transaction inside `startFromRoutine` never resolves under the fake
    // clock, so the fixture is built through `runAsync`.
    await tester.runAsync(() async {
      final exercises = ExerciseRepository(db, catalog);
      final routines = RoutineRepository(db);
      final workouts = WorkoutRepository(db);

      final exercise = await exercises.create(
        name: 'Bench press',
        muscleGroup: MuscleGroup.chest,
        equipment: Equipment.barbell,
      );
      final routine = await routines.create(name: 'Push');
      await routines.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
        targetSets: 1,
      );

      final session = await workouts.startFromRoutine(routine.id);
      final entry = (await workouts.sessionExercises(session.id)).single;
      await workouts.completeSet(entry.sets.first.id, weight: 80, reps: 8);
      await workouts.finish(session.id);
    });

    await pumpProfile(tester);

    await tester.tap(find.text('Export training log (CSV)'));
    await settle(tester);

    expect(share.calls, 1);
    expect(share.mimeType, 'text/csv');
    expect(share.fileName, endsWith('.csv'));
    expect(share.contents, contains('Bench press,1,normal,80,8,640'));
  });
}
