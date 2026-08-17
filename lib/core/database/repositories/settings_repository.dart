import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../database_provider.dart';

/// Device-local preferences.
///
/// Values are stored as text because there are few of them and they are read
/// once at startup; a typed column per setting would be more schema churn than
/// the feature is worth.
class SettingsRepository {
  const SettingsRepository(this.db);

  final AppDatabase db;

  /// Whether onboarding has already run on this device.
  static const String onboardingSeen = 'onboarding_seen';

  /// The [WeightUnit] loads are shown in, stored by enum name.
  static const String weightUnit = 'weight_unit';

  /// Rest pre-filled into a new routine slot, in seconds.
  static const String defaultRestSeconds = 'default_rest_seconds';

  /// Whether a finished rest makes a sound.
  static const String timerSound = 'timer_sound';

  Future<String?> getString(String key) async {
    final row = await (db.select(
      db.appSettings,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setString(String key, String value) {
    return db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<bool> getFlag(String key, {bool orElse = false}) async {
    final value = await getString(key);
    if (value == null) return orElse;
    return value == 'true';
  }

  Future<void> setFlag(String key, {required bool value}) =>
      setString(key, '$value');

  /// Reads an integer setting.
  ///
  /// A row holding something that is not a number reads as absent rather than
  /// throwing — the caller has a default, and a corrupt preference must not be
  /// able to stop the app from starting.
  Future<int?> getInt(String key) async {
    final value = await getString(key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> setInt(String key, int value) => setString(key, '$value');
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);
