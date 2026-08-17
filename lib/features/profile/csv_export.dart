import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog_provider.dart';
import '../../core/catalog/exercise_catalog.dart';
import '../../core/catalog/exercise_display.dart';
import '../../core/database/repositories/repositories.dart';
import '../../core/settings/preferences.dart';

/// Turns the training log into a CSV file (spec §12, a Free feature).
///
/// The prototype shows this behind a PRO lock; the spec puts it in the Free
/// list and the spec wins, for the same reason custom exercises did. An app
/// that holds your training hostage is not one that replaces a notebook.
class CsvExport {
  const CsvExport({
    required this.workouts,
    required this.catalog,
    required this.languageCode,
    required this.unit,
  });

  final WorkoutRepository workouts;
  final ExerciseCatalog catalog;

  /// Which of the catalogue's names to write. The file is for a person, and it
  /// should say "Supino reto" to someone whose app says "Supino reto".
  final String languageCode;

  /// Loads are written in the unit the user reads them in, and the header names
  /// it — `weight_lb` rather than a bare `weight` nobody can interpret two
  /// years later.
  final WeightUnit unit;

  static const String _separator = ',';
  static const String _newline = '\r\n';

  List<String> get _header => [
    'date',
    'started_at',
    'finished_at',
    'routine',
    'exercise',
    'set_number',
    'set_type',
    'weight_${unit.symbol}',
    'reps',
    'volume_${unit.symbol}',
  ];

  /// Builds the whole file in memory.
  ///
  /// A year of hard training is a few thousand rows — well under a megabyte —
  /// so this does not stream. If that ever stops being true, the shape to
  /// change is here and not at the call site.
  ///
  /// [CsvFile.setCount] comes back with it so the caller can tell an empty log
  /// apart from a failure without running the query a second time: a file with
  /// nothing but a header is not something to hand to a share sheet.
  Future<CsvFile> build() async {
    final rows = await workouts.exportCompletedSets();

    final buffer = StringBuffer()
      ..write(_header.join(_separator))
      ..write(_newline);

    for (final row in rows) {
      buffer
        ..write(_line(row).join(_separator))
        ..write(_newline);
    }

    return (contents: buffer.toString(), setCount: rows.length);
  }

  List<String> _line(ExportedSet row) {
    final set = row.set;
    final weight = set.weight;
    final reps = set.reps;
    final startedAt = row.session.startedAt;

    return [
      _date(startedAt.toLocal()),
      // The timestamps stay UTC, exactly as stored: a training log that spans a
      // holiday abroad has to stay orderable, and only the local date column is
      // there to answer "which day was that".
      startedAt.toIso8601String(),
      row.session.finishedAt?.toIso8601String() ?? '',
      _escape(row.routineName ?? ''),
      _escape(row.exercise.displayName(catalog, languageCode)),
      '${set.setNumber}',
      set.type.name,
      weight == null ? '' : _number(unit.fromKilograms(weight)),
      reps?.toString() ?? '',
      weight == null || reps == null
          ? ''
          : _number(unit.fromKilograms(weight) * reps),
    ];
  }

  static String _date(DateTime local) {
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Always a `.` decimal separator, never the locale's.
  ///
  /// A Brazilian locale would write `22,5`, which in a comma-delimited file is
  /// two columns. The delimiter wins over the locale; every spreadsheet on
  /// earth can be told to read a dot.
  static String _number(double value) {
    final rounded = (value * 100).roundToDouble() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  /// RFC 4180 quoting.
  ///
  /// Exercise and routine names are free text the user typed. "Supino reto,
  /// pegada fechada" is a perfectly reasonable name and would otherwise shift
  /// every column after it by one.
  static String _escape(String value) {
    final needsQuotes =
        value.contains(_separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

/// A generated export, and how many sets went into it.
typedef CsvFile = ({String contents, int setCount});

final csvExportProvider = Provider.family<CsvExport, String>(
  (ref, languageCode) => CsvExport(
    workouts: ref.watch(workoutRepositoryProvider),
    catalog: ref.watch(exerciseCatalogProvider),
    languageCode: languageCode,
    unit: ref.watch(weightUnitProvider),
  ),
);
