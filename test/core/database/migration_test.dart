import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';

/// Reproduces upgrading an install that predates a schema change.
///
/// A file-backed database, not the in-memory one every other test uses: the
/// whole point is that the data survives being closed and reopened, which is
/// what a real device does between app versions.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pwr_migration');
    file = File('${dir.path}/pwr.sqlite');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  Future<Set<String>> tablesOf(AppDatabase db) async {
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          '''WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ''',
        )
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test('the current schema version is 2', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(db.schemaVersion, 2);
    db.close();
  });

  test('a version 1 database gains app_settings on open', () async {
    // Build the file the way version 1 left it: every table except the one
    // that came with version 2.
    final v1 = AppDatabase.forTesting(NativeDatabase(file));
    await v1.customStatement('SELECT 1');
    await v1.customStatement('DROP TABLE app_settings');
    await v1.customStatement('PRAGMA user_version = 1');
    expect(await tablesOf(v1), isNot(contains('app_settings')));
    await v1.close();

    // Reopening with the current code is exactly what an app update does.
    final v2 = AppDatabase.forTesting(NativeDatabase(file));
    expect(await tablesOf(v2), contains('app_settings'));

    // And the table is usable, not merely present — this is the read that
    // crashed on startup before the migration existed.
    final settings = SettingsRepository(v2);
    expect(await settings.getFlag(SettingsRepository.onboardingSeen), isFalse);

    await v2.close();
  });

  test('upgrading keeps the data that was already there', () async {
    final v1 = AppDatabase.forTesting(NativeDatabase(file));
    final routine = await RoutineRepository(v1).create(name: 'Push A');
    await v1.customStatement('DROP TABLE app_settings');
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    final v2 = AppDatabase.forTesting(NativeDatabase(file));
    final kept = await RoutineRepository(v2).findById(routine.id);

    // A migration that quietly wiped the user's routines would be worse than
    // the crash it replaced.
    expect(kept?.name, 'Push A');

    await v2.close();
  });

  test('opening an already current database changes nothing', () async {
    final first = AppDatabase.forTesting(NativeDatabase(file));
    await SettingsRepository(first).setFlag('probe', value: true);
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(file));
    expect(await SettingsRepository(second).getFlag('probe'), isTrue);
    expect(await tablesOf(second), contains('app_settings'));
    await second.close();
  });
}
