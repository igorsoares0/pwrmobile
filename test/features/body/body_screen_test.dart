import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/app/theme/theme.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/core/settings/preferences.dart';
import 'package:pwrmobile/features/body/body_screen.dart';
import 'package:pwrmobile/l10n/app_localizations.dart';
import 'package:pwrmobile/shared/widgets/widgets.dart';

/// A weight as it appears in the history list.
///
/// Scoped to the rows, because the header card renders the identical string:
/// `find.text` flattens a `Text.rich` to its plain text, so a bare finder
/// matches both and `tap` refuses an ambiguous target.
Finder historyRow(String label) => find.descendant(
  of: find.byType(PwrListRow),
  matching: find.text(label),
);

/// Bounded pumps, long enough to outlast a modal sheet's 250ms entrance.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  late AppDatabase db;
  late BodyRepository body;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    body = BodyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime daysAgo(int days) =>
      DateTime.now().toUtc().subtract(Duration(days: days));

  /// A widget test that flushes drift's cache timers before it ends.
  ///
  /// See `home_screen_test.dart` for why this cannot live in `tearDown`.
  void testBody(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    });
  }

  Future<ProviderContainer> pumpBody(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PwrTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BodyScreen(),
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  testBody('a fresh install explains what the screen is for', (tester) async {
    await pumpBody(tester);

    expect(find.text('No weigh-ins yet.'), findsOneWidget);
    // The perimeters are visible but locked — hiding them would make the
    // screen look finished.
    expect(find.text('Chest'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(4));
  });

  testBody('the current weight and its change are shown', (tester) async {
    await tester.runAsync(() async {
      await body.log(weightKg: 80.6, measuredAt: daysAgo(30));
      await body.log(weightKg: 82.4, measuredAt: daysAgo(2));
    });

    await pumpBody(tester);

    // The headline is a `Text.rich` so the unit can be styled down, which is
    // why it needs `findRichText`; the history row below is a plain string.
    expect(
      find.textContaining('82.4', findRichText: true),
      findsNWidgets(2),
    );
    expect(find.text('▲ +1.8KG'), findsOneWidget);
    expect(find.text('IN 4 WEEKS'), findsOneWidget);
  });

  testBody('a single weigh-in says there is nothing to compare yet', (
    tester,
  ) async {
    await tester.runAsync(() => body.log(weightKg: 82.4));

    await pumpBody(tester);

    expect(historyRow('82.4 KG'), findsOneWidget);
    // Not "+0.0KG", which would read as a stalled month rather than a first
    // entry.
    expect(find.text('FIRST ENTRY'), findsOneWidget);
  });

  testBody('logging a weight writes it and the list picks it up', (
    tester,
  ) async {
    await pumpBody(tester);

    await tester.tap(find.text('Log weight'));
    await settle(tester);

    await tester.enterText(find.byType(TextField), '82.4');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('No weigh-ins yet.'), findsNothing);
    expect(historyRow('82.4 KG'), findsOneWidget);

    final stored = await tester.runAsync(
      () => body.watchMeasurements().first,
    );
    expect(stored!.single.weightKg, 82.4);
  });

  testBody('a weight typed in pounds is stored in kilograms', (tester) async {
    final container = await pumpBody(tester);
    await tester.runAsync(
      () => container.read(preferencesProvider.notifier).setWeightUnit(
        WeightUnit.lb,
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Log weight'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '180');
    await tester.tap(find.text('Save'));
    await settle(tester);

    final stored = await tester.runAsync(
      () => body.watchMeasurements().first,
    );

    // 180 lb is 81.6 kg. The column is the canonical unit whatever the user
    // typed, or a switch mid-year would make the trend line meaningless.
    expect(stored!.single.weightKg, closeTo(81.647, 0.001));
    expect(historyRow('180 LB'), findsOneWidget);
  });

  testBody('an entry can be corrected', (tester) async {
    await tester.runAsync(() => body.log(weightKg: 8.24));

    await pumpBody(tester);

    await tester.tap(historyRow('8.2 KG'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '82.4');
    await tester.tap(find.text('Save'));
    await settle(tester);

    final stored = await tester.runAsync(
      () => body.watchMeasurements().first,
    );
    expect(stored!.single.weightKg, 82.4);
  });

  testBody('an entry can be deleted', (tester) async {
    await tester.runAsync(() => body.log(weightKg: 82.4));

    await pumpBody(tester);

    await tester.tap(historyRow('82.4 KG'));
    await settle(tester);
    await tester.tap(find.text('Delete this entry'));
    await settle(tester);

    expect(find.text('No weigh-ins yet.'), findsOneWidget);
  });
}
