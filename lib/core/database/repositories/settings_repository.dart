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

  Future<bool> getFlag(String key, {bool orElse = false}) async {
    final row = await (db.select(
      db.appSettings,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    if (row == null) return orElse;
    return row.value == 'true';
  }

  Future<void> setFlag(String key, {required bool value}) {
    return db
        .into(db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: '$value',
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);
