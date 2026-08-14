import 'package:intl/intl.dart';

/// A load rendered for display, split so the unit can be styled separately.
typedef FormattedLoad = ({String value, String unit});

/// Formats a load in kilograms.
///
/// [compact] trades precision for width, switching to tonnes past four digits:
/// `18.4 t` fits a stat tile where `18437 kg` would not, and nobody reading a
/// weekly total cares about the last kilogram.
///
/// Pass `compact: false` where the number is the headline. A single session's
/// volume belongs there — rounding 1150 kg to `1.1 t` throws away 50 kg that
/// the user did lift, and the figure has room to be exact.
FormattedLoad formatLoad(
  double kilograms,
  String locale, {
  bool compact = true,
}) {
  if (compact && kilograms >= 1000) {
    final tonnes = NumberFormat('0.#', locale).format(kilograms / 1000);
    return (value: tonnes, unit: 't');
  }
  return (value: NumberFormat('#,##0', locale).format(kilograms), unit: 'kg');
}

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
