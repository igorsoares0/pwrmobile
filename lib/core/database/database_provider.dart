import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The application-wide database handle.
///
/// One connection for the whole app. Overridden in tests and in the design
/// gallery with `AppDatabase.forTesting(NativeDatabase.memory())`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
