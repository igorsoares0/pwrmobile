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
import 'package:pwrmobile/features/sharing/share_card.dart';
import 'package:pwrmobile/features/sharing/share_service.dart';
import 'package:pwrmobile/features/workout/workout_summary_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Records what would have been handed to the system share sheet.
class _RecordingShareService implements ShareService {
  Uint8List? bytes;
  String? fileName;
  String? subject;
  int calls = 0;

  String? contents;

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? subject,
  }) async {
    calls++;
    this.bytes = bytes;
    this.fileName = fileName;
    this.subject = subject;
  }

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
    this.subject = subject;
  }
}

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late RoutineRepository routines;
  late ExerciseRepository exercises;
  late WorkoutRepository workouts;
  late Routine routine;
  late _RecordingShareService share;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = ExerciseCatalog.parse(
      File('assets/catalog/exercises.json').readAsStringSync(),
    );
    routines = RoutineRepository(db);
    exercises = ExerciseRepository(db, catalog);
    workouts = WorkoutRepository(db);
    share = _RecordingShareService();

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

  void testShare(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }

  /// `startFromRoutine` opens a drift transaction, which never completes under
  /// a widget test's fake clock.
  Future<T> realAsync<T>(WidgetTester tester, Future<T> Function() body) async {
    return (await tester.runAsync(body)) as T;
  }

  Future<String> runSession(List<(double, int)> sets) async {
    final session = await workouts.startFromRoutine(routine.id);
    final details = await workouts.sessionExercises(session.id);
    for (var i = 0; i < sets.length; i++) {
      await workouts.completeSet(
        details.single.sets[i].id,
        weight: sets[i].$1,
        reps: sets[i].$2,
      );
    }
    await workouts.finish(session.id);
    return session.id;
  }

  Future<void> pumpSummary(WidgetTester tester, String sessionId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWithValue(catalog),
          shareServiceProvider.overrideWithValue(share),
        ],
        child: MaterialApp(
          theme: PwrTheme.dark,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkoutSummaryScreen(sessionId: sessionId),
        ),
      ),
    );
    await settle(tester);
  }

  group('the card', () {
    testShare('carries the routine, the load and the best set', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8), (85, 6)]));
      await pumpSummary(tester, id);

      await tester.tap(find.text('Compartilhar'));
      await settle(tester);

      expect(find.byType(ShareCard), findsOneWidget);
      expect(find.text('PUSH A'), findsOneWidget);
      expect(find.textContaining('1.150'), findsWidgets);
      expect(find.text('MELHOR SÉRIE'), findsOneWidget);
      // 85 beats 80 on load, so that is the set worth showing.
      expect(find.text('85 KG × 6'), findsOneWidget);
    });

    testShare('has a fixed size so every device exports the same image', (
      tester,
    ) async {
      final id = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, id);

      await tester.tap(find.text('Compartilhar'));
      await settle(tester);

      final size = tester.getSize(find.byType(ShareCard));
      expect(size, ShareCard.logicalSize);
    });
  });

  group('sharing', () {
    testShare('hands a PNG to the system share sheet', (tester) async {
      final id = await realAsync(tester, () => runSession([(80, 8)]));
      await pumpSummary(tester, id);

      await tester.tap(find.text('Compartilhar'));
      await settle(tester);
      await tester.tap(find.text('Compartilhar imagem'));

      // `toImage()` is real async — it rasterises through the engine — so it
      // cannot complete under the fake clock a widget test installs. Letting
      // the real zone run is what makes the capture finish.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await settle(tester);

      expect(share.calls, 1);
      expect(share.fileName, endsWith('.png'));
      expect(share.subject, contains('Push A'));

      // Real bytes, not a stub: PNG files start with this signature.
      final bytes = share.bytes!;
      expect(bytes.length, greaterThan(1000));
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    });

    testShare('a session with nothing logged is not offered', (tester) async {
      final session = await realAsync(
        tester,
        () => workouts.startFromRoutine(routine.id),
      );
      await realAsync(tester, () => workouts.finish(session.id));
      await pumpSummary(tester, session.id);

      // Nothing to brag about, so no card.
      expect(find.text('Compartilhar'), findsNothing);
    });
  });

  group('captureBoundary', () {
    testShare('returns null when the boundary was never laid out', (
      tester,
    ) async {
      final bytes = await captureBoundary(GlobalKey());

      expect(bytes, isNull);
    });
  });
}
