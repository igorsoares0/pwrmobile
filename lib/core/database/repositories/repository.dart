import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_database.dart';

/// Base for repositories over [SyncedTable]-backed tables.
///
/// The point of this layer is that no feature should ever have to remember the
/// offline-first bookkeeping. Reads filter tombstones, writes bump the revision
/// counter, deletes are soft. Getting one of those wrong in a feature would not
/// fail loudly — it would quietly corrupt what the backend sees in Phase 3 —
/// so the rules live here instead.
abstract class Repository {
  const Repository(this.db);

  final AppDatabase db;

  @protected
  DateTime nowUtc() => DateTime.now().toUtc();

  /// Records a local mutation of [id]: increments `version` and stamps
  /// `updatedAt`.
  ///
  /// Call this inside the same transaction as the change it describes.
  ///
  /// Uses [AppDatabase.customUpdate] rather than a typed companion for two
  /// reasons: `version = version + 1` has to be evaluated by SQLite so that
  /// concurrent writers cannot both read the same value, and passing the
  /// timestamp as a typed [Variable] lets drift apply its own `DateTime`
  /// encoding instead of this code hard-coding a text format that the build
  /// options control.
  @protected
  Future<void> touch(TableInfo<Table, dynamic> table, String id) {
    return db.customUpdate(
      'UPDATE ${table.actualTableName} '
      'SET version = version + 1, updated_at = ? '
      'WHERE id = ?',
      variables: [Variable<DateTime>(nowUtc()), Variable<String>(id)],
      updates: {table},
    );
  }

  /// Tombstones [id].
  ///
  /// Never issues a `DELETE`: without a surviving row the backend has no
  /// tombstone to replicate, and the next pull on another device would
  /// resurrect the record.
  ///
  /// The `deleted_at IS NULL` guard makes this idempotent — deleting twice
  /// must not inflate the version and re-queue a second sync operation.
  @protected
  Future<void> softDelete(TableInfo<Table, dynamic> table, String id) {
    final now = nowUtc();
    return db.customUpdate(
      'UPDATE ${table.actualTableName} '
      'SET deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<DateTime>(now),
        Variable<DateTime>(now),
        Variable<String>(id),
      ],
      updates: {table},
    );
  }
}
