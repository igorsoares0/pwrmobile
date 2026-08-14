import 'package:drift/drift.dart';

/// Device-local key-value preferences.
///
/// Deliberately **not** a [SyncedTable]: these are facts about this
/// installation, not about the user. Whether onboarding has been seen on this
/// phone says nothing about their tablet, and pushing it to the backend would
/// make one device's state overwrite another's.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {key};
}
