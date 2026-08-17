import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../database_provider.dart';
import 'models.dart';
import 'repository.dart';

/// Body weight over time (spec §6).
///
/// Everything here is in kilograms. Conversion is a display concern and lives
/// in `WeightUnit`, so a user who switches units mid-year does not end up with
/// a trend line made of two different scales.
class BodyRepository extends Repository {
  const BodyRepository(super.db);

  /// Every entry, newest first.
  ///
  /// Ordered by [BodyMeasurement.measuredAt] and not by id: a user catching up
  /// on Monday for a Saturday weigh-in inserts a row whose id sorts last but
  /// whose measurement belongs in the middle.
  Stream<List<BodyMeasurement>> watchMeasurements({int limit = 100}) {
    return (db.select(db.bodyMeasurements)
          ..where((tbl) => tbl.deletedAt.isNull() & tbl.weightKg.isNotNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.measuredAt)])
          ..limit(limit))
        .watch();
  }

  /// The current weight and how far it has moved, for the header card.
  ///
  /// One query rather than two, and the arithmetic in Dart rather than SQL:
  /// the whole series is already being read for the list underneath, and a
  /// hundred rows is not something to optimise around.
  Stream<BodyTrend?> watchTrend({Duration window = const Duration(days: 84)}) {
    return watchMeasurements().map((entries) {
      if (entries.isEmpty) return null;

      final latest = entries.first;
      final since = latest.measuredAt.subtract(window);

      // The oldest entry still inside the window, which is the one the delta
      // is measured from. Entries are newest first, so this walks backwards.
      final baseline = entries.lastWhere(
        (entry) => !entry.measuredAt.isBefore(since),
        orElse: () => latest,
      );

      return BodyTrend(
        latest: latest,
        baseline: baseline.id == latest.id ? null : baseline,
        window: window,
      );
    });
  }

  Future<BodyMeasurement?> findById(String id) {
    return (db.select(db.bodyMeasurements)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<BodyMeasurement> log({
    required double weightKg,
    DateTime? measuredAt,
    String? notes,
  }) {
    return db
        .into(db.bodyMeasurements)
        .insertReturning(
          BodyMeasurementsCompanion.insert(
            weightKg: Value(weightKg),
            measuredAt: Value((measuredAt ?? nowUtc()).toUtc()),
            notes: Value(notes?.trim()),
          ),
        );
  }

  /// Corrects an entry.
  ///
  /// A weigh-in is a single number typed on a phone with wet hands; getting it
  /// wrong and being unable to fix it would make the trend permanently untrue.
  Future<void> update(
    String id, {
    double? weightKg,
    DateTime? measuredAt,
    String? notes,
  }) {
    return db.transaction(() async {
      await (db.update(
        db.bodyMeasurements,
      )..where((tbl) => tbl.id.equals(id))).write(
        BodyMeasurementsCompanion(
          weightKg: Value.absentIfNull(weightKg),
          measuredAt: Value.absentIfNull(measuredAt?.toUtc()),
          notes: Value.absentIfNull(notes?.trim()),
        ),
      );
      await touch(db.bodyMeasurements, id);
    });
  }

  Future<void> remove(String id) => softDelete(db.bodyMeasurements, id);
}

final bodyRepositoryProvider = Provider<BodyRepository>(
  (ref) => BodyRepository(ref.watch(appDatabaseProvider)),
);
