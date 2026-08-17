import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/database_provider.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/core/settings/preferences.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    settings = SettingsRepository(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('WeightUnit', () {
    test('converts a load and converts it back', () {
      const hundred = 100.0;
      final pounds = WeightUnit.lb.fromKilograms(hundred);

      expect(pounds, closeTo(220.462, 0.001));
      expect(WeightUnit.lb.toKilograms(pounds), closeTo(hundred, 1e-9));
    });

    test('kilograms are the identity', () {
      expect(WeightUnit.kg.fromKilograms(82.5), 82.5);
      expect(WeightUnit.kg.toKilograms(82.5), 82.5);
    });

    test('an unknown stored name falls back to kilograms', () {
      // A settings row written by a build that knew a unit this one does not
      // must not be able to stop the app from starting.
      expect(WeightUnit.byName('stone'), WeightUnit.kg);
      expect(WeightUnit.byName(null), WeightUnit.kg);
      expect(WeightUnit.byName('lb'), WeightUnit.lb);
    });
  });

  group('preferences', () {
    test('a fresh install reads the documented defaults', () async {
      final preferences = await loadPreferences(settings);

      expect(preferences.weightUnit, WeightUnit.kg);
      expect(preferences.defaultRestSeconds, Preferences.defaultRest);
      expect(preferences.timerSound, isTrue);
    });

    test('every setter survives a restart', () async {
      final controller = container.read(preferencesProvider.notifier);

      await controller.setWeightUnit(WeightUnit.lb);
      await controller.setDefaultRestSeconds(120);
      await controller.setTimerSound(enabled: false);

      // Read straight off disk rather than from the notifier: the point is
      // that the next launch's `loadPreferences` sees them.
      final reloaded = await loadPreferences(settings);

      expect(reloaded.weightUnit, WeightUnit.lb);
      expect(reloaded.defaultRestSeconds, 120);
      expect(reloaded.timerSound, isFalse);
    });

    test('the state moves before the write resolves', () {
      final controller = container.read(preferencesProvider.notifier);

      // Deliberately not awaited: a switch that waits on SQLite before it
      // moves feels broken, so the state is expected to be current already.
      controller.setWeightUnit(WeightUnit.lb);

      expect(container.read(weightUnitProvider), WeightUnit.lb);
    });

    test('a corrupt integer setting reads as absent', () async {
      await settings.setString(SettingsRepository.defaultRestSeconds, 'ninety');

      final preferences = await loadPreferences(settings);

      expect(preferences.defaultRestSeconds, Preferences.defaultRest);
    });
  });
}
