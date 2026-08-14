import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates the identifier for a new row.
///
/// UUID **v7**, not v4: v7 embeds a millisecond timestamp in its high bits, so
/// identifiers sort roughly by creation time. That keeps B-tree inserts
/// append-only instead of scattering them across the index.
///
/// The ordering guarantee is millisecond-granular — the bits below the
/// timestamp are random, so two ids minted in the same millisecond have no
/// defined order between them. Never rely on id order where real chronology
/// matters; sort on the timestamp column instead.
String newEntityId() => _uuid.v7();

/// Namespace for every deterministic PWR identifier.
///
/// An arbitrary but permanent UUID. Changing it re-mints every catalogue id
/// and would orphan the workout history of every existing install, so it must
/// never change once released.
const String pwrIdNamespace = '7f9c2b14-3d6e-4a58-9c21-0b5e8a1f4d73';

/// Derives the stable identifier of a catalogue row from its slug.
///
/// UUID **v5**, which is a hash of namespace plus name: the same slug yields
/// the same id on every device, every install, forever.
///
/// This is what stops the seeded library from multiplying. With random ids,
/// a user's phone and tablet would each mint their own "Barbell Bench Press",
/// and Phase 3 sync would see two unrelated rows rather than one — with each
/// device's history pointing at its own copy, unmergeable after the fact.
String catalogEntityId(String kind, String slug) =>
    _uuid.v5(pwrIdNamespace, '$kind:$slug');

/// Columns every synchronizable entity carries.
///
/// Three invariants come from the offline-first design (spec §5 and §8) and
/// hold for every table mixing this in:
///
/// 1. **The device mints the id.** Rows are created offline and must be
///    referenceable before the backend has ever seen them, so ids are never
///    server-assigned and never sequential.
/// 2. **Deletes are soft.** [deletedAt] is set instead of removing the row —
///    a hard delete leaves the backend no tombstone to replicate, and other
///    devices would resurrect the row on their next pull.
/// 3. **Every mutation bumps [version].** Conflict resolution pairs it with
///    [updatedAt]: highest version wins, [updatedAt] breaks ties.
mixin SyncedTable on Table {
  /// Client-generated UUID v7. Primary key across every device and the server.
  TextColumn get id => text().clientDefault(newEntityId)();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Last local mutation. Written on every update, never by the sync layer
  /// alone — a pulled row carries the origin device's value.
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Tombstone marker. Non-null means the row is deleted and must be filtered
  /// out of every user-facing query.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Monotonic revision counter, starting at 1.
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
