import 'package:drift/drift.dart';

import '../enums.dart';
import 'synced_table.dart';

/// The outbound sync queue.
///
/// Every local mutation appends a row here; the sync layer drains it whenever
/// the network allows. This table is **not** itself synchronized — it is local
/// bookkeeping, so it deliberately does not mix in [SyncedTable].
///
/// The queue is only built in Phase 3. The table exists from schema version 1
/// so that turning sync on later needs no migration of user data.
@TableIndex(name: 'idx_sync_operations_pending', columns: {#syncedAt})
@TableIndex(
  name: 'idx_sync_operations_entity',
  columns: {#entityType, #entityId},
)
class SyncOperations extends Table {
  TextColumn get id => text().clientDefault(newEntityId)();

  TextColumn get entityType => textEnum<SyncEntityType>()();

  /// Id of the affected row. No foreign key: the operation must outlive a hard
  /// delete of its target and still be pushable.
  TextColumn get entityId => text()();

  TextColumn get operation => textEnum<SyncOperationType>()();

  /// JSON snapshot of the entity at enqueue time.
  ///
  /// Serialized eagerly rather than read back at push time, so replaying the
  /// queue sends what actually happened instead of whatever the row looks like
  /// by the time the network returns.
  TextColumn get payload => text()();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Push attempts so far. Drives backoff and the give-up threshold.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  /// Null while pending. Set once the backend has acknowledged the operation.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
