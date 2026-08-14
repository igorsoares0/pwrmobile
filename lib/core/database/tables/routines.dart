import 'package:drift/drift.dart';

import 'synced_table.dart';

/// A workout template — "Push A", "Pull B", "Legs".
///
/// The Free plan caps these at three (spec §12). The limit is enforced in the
/// repository rather than here: it is a product rule that PRO lifts, not a
/// data-integrity constraint.
@TableIndex(name: 'idx_routines_position', columns: {#position})
class Routines extends Table with SyncedTable {
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// The muscle focus shown under the name — "Peito & Tríceps".
  TextColumn get focus => text().nullable().withLength(max: 120)();

  /// Sort order on the home screen. Sparse and user-controlled via drag.
  IntColumn get position => integer().withDefault(const Constant(0))();

  TextColumn get notes => text().nullable()();
}
