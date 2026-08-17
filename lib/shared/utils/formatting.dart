import 'package:intl/intl.dart';

import '../../core/settings/weight_unit.dart';

/// A load rendered for display, split so the unit can be styled separately.
typedef FormattedLoad = ({String value, String unit});

/// Formats a total load, stored in kilograms, into [unit].
///
/// [compact] trades precision for width, switching magnitude past four digits:
/// `18.4 t` fits a stat tile where `18437 kg` would not, and nobody reading a
/// weekly total cares about the last kilogram.
///
/// Kilograms have a name for a thousand of themselves and pounds do not, so the
/// two compact differently: `18.4 t` against `40.6k lb`. Both are how each
/// system is actually written; forcing one shape onto the other would produce
/// either `40.6 klb` or a six-digit number the tile cannot hold.
///
/// Pass `compact: false` where the number is the headline. A single session's
/// volume belongs there — rounding 1150 kg to `1.1 t` throws away 50 kg that
/// the user did lift, and the figure has room to be exact.
FormattedLoad formatLoad(
  double kilograms,
  String locale, {
  bool compact = true,
  WeightUnit unit = WeightUnit.kg,
}) {
  final value = unit.fromKilograms(kilograms);

  if (compact && value >= 1000) {
    final scaled = NumberFormat('0.#', locale).format(value / 1000);
    return switch (unit) {
      WeightUnit.kg => (value: scaled, unit: 't'),
      WeightUnit.lb => (value: '${scaled}k', unit: unit.symbol),
    };
  }
  return (
    value: NumberFormat('#,##0', locale).format(value),
    unit: unit.symbol,
  );
}

/// Formats one set's load, stored in kilograms, into [unit].
///
/// Separate from [formatLoad] because a single set is not a total: `22.5 kg`
/// has to survive as `22.5`, where a session volume rounds to the whole unit
/// without losing anything a user would notice. Running a set weight through
/// the volume formatter is what turned `22.5` into `23` on the share card.
///
/// One decimal at most. A conversion produces figures like `220.46226 lb`,
/// which is precision no barbell in any gym has.
String formatSetLoad(double kilograms, String locale, {
  WeightUnit unit = WeightUnit.kg,
}) => NumberFormat('0.#', locale).format(unit.fromKilograms(kilograms));

/// Formats a duration as the `~58 min` hint on a routine card.
int roundedMinutes(Duration duration) => (duration.inSeconds / 60).round();

/// The ISO-8601 week number of [date].
///
/// ISO weeks start on Monday, and week 1 is the one containing the first
/// Thursday of the year — which is why this counts from the Thursday of
/// [date]'s week rather than from January 1st.
int isoWeekNumber(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final thursday = local.add(Duration(days: DateTime.thursday - local.weekday));
  final firstOfYear = DateTime(thursday.year);
  final daysSince = thursday.difference(firstOfYear).inDays;
  return daysSince ~/ 7 + 1;
}

/// The weekday name for [date], capitalised for the locale.
String weekdayName(DateTime date, String locale) =>
    DateFormat.EEEE(locale).format(date);

/// Formats a duration as `MM:SS`, or `H:MM:SS` past an hour.
///
/// Used for both the session clock and the rest countdown, so they read as the
/// same kind of number. Negative durations clamp to zero — a finished rest
/// shows `00:00`, never `-00:01`.
String formatClock(Duration duration) {
  final total = duration.isNegative ? Duration.zero : duration;
  final seconds = total.inSeconds % 60;
  final minutes = total.inMinutes % 60;
  final hours = total.inHours;

  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
}
