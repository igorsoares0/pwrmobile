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
import 'package:pwrmobile/core/database/exercise_seeder.dart';
import 'package:pwrmobile/features/exercises/exercise_library_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';

/// Bounded pumps. See the note on `testLibrary` for why not `pumpAndSettle`.
Future<void> settle(WidgetTester tester) async {
  // Long enough to cover a modal sheet's entrance animation, still bounded.
  for (var i = 0; i < 8; i++) {
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

  /// A widget test that flushes drift's query-cache timers before it ends.
  ///
  /// Each cancelled stream schedules a `Timer.run` to expire its cache, and the
  /// binding asserts none are pending — before package:test teardowns run, so
  /// the flush has to happen here. Never `await db.close()` in the body: it
  /// waits on exactly these timers, which only fire when the test pumps.
  void testLibrary(
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

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Locale locale = const Locale('pt'),
    void Function(Exercise)? onSelect,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogProvider.overrideWithValue(catalog),
        ],
        child: MaterialApp(
          theme: PwrTheme.dark,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExerciseLibraryScreen(onSelect: onSelect),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField).first, query);
    await settle(tester);
  }

  group('browsing', () {
    testLibrary('groups the catalogue under region headings', (tester) async {
      await pumpLibrary(tester);

      // Only the first section is asserted: a ListView builds lazily, so the
      // regions below the fold do not exist yet. Filtering covers the rest.
      expect(find.textContaining('PEITO · '), findsOneWidget);
      expect(find.text('Supino reto com barra'), findsOneWidget);
    });

    testLibrary('shows equipment as the row subtitle', (tester) async {
      await pumpLibrary(tester);

      expect(find.text('BARRA'), findsWidgets);
    });

    testLibrary('offers creating a custom exercise', (tester) async {
      await pumpLibrary(tester);
      // Narrowing the list is what brings the row into view. Scrolling is not
      // an option here: `scrollUntilVisible` drives `pumpAndSettle`, and it
      // cannot choose between the chip strip and the section list.
      await type(tester, 'burpee');

      // Free feature per spec §12, despite the prototype showing a lock.
      expect(find.text('Criar exercício próprio'), findsOneWidget);
    });

    testLibrary('reports the selected exercise', (tester) async {
      Exercise? picked;
      await pumpLibrary(tester, onSelect: (e) => picked = e);

      await tester.tap(find.text('Supino reto com barra'));
      await settle(tester);

      expect(picked?.slug, 'barbell-bench-press');
    });
  });

  group('filtering', () {
    testLibrary('a region chip narrows the list to that region', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Costas'));
      await settle(tester);

      expect(find.textContaining('COSTAS · '), findsOneWidget);
      expect(find.textContaining('PEITO · '), findsNothing);
    });

    testLibrary('tapping the active chip clears it', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Costas'));
      await settle(tester);
      await tester.tap(find.text('Costas'));
      await settle(tester);

      expect(find.textContaining('PEITO · '), findsOneWidget);
    });
  });

  group('search', () {
    testLibrary('finds a catalogue exercise by its Portuguese name', (
      tester,
    ) async {
      await pumpLibrary(tester);
      await type(tester, 'supino');

      expect(find.text('Supino reto com barra'), findsOneWidget);
      expect(find.text('Agachamento livre'), findsNothing);
    });

    testLibrary('finds the same exercise by its English name', (tester) async {
      await pumpLibrary(tester);
      await type(tester, 'bench press');

      // The screen is in Portuguese, but the user typed English — the
      // catalogue matches on every locale it carries.
      expect(find.text('Supino reto com barra'), findsOneWidget);
    });

    testLibrary('ignores diacritics', (tester) async {
      await pumpLibrary(tester);
      await type(tester, 'triceps');

      expect(find.textContaining('Tríceps'), findsWidgets);
    });

    testLibrary('a search matching nothing offers to create it', (
      tester,
    ) async {
      await pumpLibrary(tester);
      await type(tester, 'zzzznope');

      // Twice: once in the search field, once in the empty-state headline.
      expect(find.textContaining('zzzznope'), findsNWidgets(2));
      expect(
        find.text('Confira a grafia, ou cadastre como exercício próprio.'),
        findsOneWidget,
      );
    });
  });

  group('creating', () {
    testLibrary('a saved exercise appears in the library', (tester) async {
      await pumpLibrary(tester);
      await type(tester, 'Puxada do Zé');

      await tester.tap(find.text('Criar exercício próprio'));
      await settle(tester);

      expect(find.text('Novo exercício'), findsOneWidget);
      // The failed search is carried into the sheet.
      expect(find.text('Puxada do Zé'), findsWidgets);

      await tester.tap(find.text('Salvar exercício'));
      await settle(tester);

      // Asserted through the UI on purpose. Awaiting a drift stream here
      // (`watchLibrary(...).first`) deadlocks the test: its first emission
      // waits on a timer that only a pump can fire.
      expect(find.text('Novo exercício'), findsNothing);
      expect(find.text('Puxada do Zé'), findsWidgets);
      expect(find.textContaining('SEU'), findsOneWidget);
    });

    testLibrary('refuses to save without a name', (tester) async {
      await pumpLibrary(tester);
      await type(tester, 'burpee');
      await tester.tap(find.text('Criar exercício próprio'));
      await settle(tester);

      // The sheet prefills the name from the search term, so it has to be
      // cleared for this to be the empty-name case at all. `.last` is the
      // sheet's field; the library's search box is still mounted behind it.
      await tester.enterText(find.byType(TextField).last, '');
      await settle(tester);

      await tester.tap(find.text('Salvar exercício'));
      await settle(tester);

      expect(find.text('Dê um nome primeiro.'), findsOneWidget);
      expect(find.text('Novo exercício'), findsOneWidget);
    });
  });

  group('localisation', () {
    testLibrary('renders in English', (tester) async {
      await pumpLibrary(tester, locale: const Locale('en'));

      expect(find.text('Exercise library'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.textContaining('CHEST · '), findsOneWidget);
    });

    testLibrary('renders in Portuguese', (tester) async {
      await pumpLibrary(tester);

      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Supino reto com barra'), findsOneWidget);
    });
  });
}
