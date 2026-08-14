import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'enums.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// The local SQLite database.
///
/// This is the source of truth for the app. Nothing in the workout flow reads
/// from or waits on the network; the backend is a replica that catches up
/// later (spec §22, principles 1–4).
@DriftDatabase(
  tables: [
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    WorkoutExercises,
    WorkoutSets,
    SyncOperations,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructs a database over an existing executor. Used by tests to run
  /// against an in-memory database.
  AppDatabase.forTesting(super.executor);

  /// Bump this on **every** schema change and add a matching step below.
  ///
  /// Skipping it because the app has not shipped is a trap: a development
  /// device is an install too, and it opens the old file with the new code.
  /// Adding `app_settings` without a version bump is exactly how this app
  /// started failing to boot.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // 1 → 2: device-local preferences, which onboarding needs to remember
      // that it has run.
      if (from < 2) {
        await m.createTable(appSettings);
      }
    },
    beforeOpen: (details) async {
      // SQLite leaves foreign keys unenforced unless asked, per connection.
      // Without this the references declared on the tables are documentation
      // rather than constraints.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'pwr');
}
