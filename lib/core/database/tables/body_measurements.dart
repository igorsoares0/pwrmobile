import 'package:drift/drift.dart';

import 'synced_table.dart';

/// One trip to the scale (spec §6).
///
/// Weight only, for now. The prototype's grid of perimeters — chest, waist,
/// arm, thigh — and its progress photos are "medições corporais avançadas",
/// which spec §13 puts in PRO; the body screen shows them as locked rather
/// than storing columns nothing writes to. Adding them later is one nullable
/// column each and one migration step.
///
/// [weightKg] is nevertheless nullable, so that day never needs a *data*
/// migration: an entry that recorded a waist and no weight has to be
/// expressible the moment perimeters exist.
@TableIndex(name: 'idx_body_measurements_measured_at', columns: {#measuredAt})
class BodyMeasurements extends Table with SyncedTable {
  /// When the user stepped on the scale, not when they typed it in.
  ///
  /// Someone catching up on Monday for a Saturday weigh-in must be able to put
  /// it on Saturday, or the trend line lies. Stored UTC like every other
  /// timestamp here; the screen renders it local.
  DateTimeColumn get measuredAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Body weight in kilograms.
  ///
  /// Kilograms for exactly the reason loads are: one canonical unit keeps a
  /// trend comparable for a user who switches what they read. [WeightUnit] is
  /// the only place that converts.
  RealColumn get weightKg => real().nullable()();

  TextColumn get notes => text().nullable()();
}
