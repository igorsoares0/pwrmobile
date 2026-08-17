/// The unit a load is shown in and typed in.
///
/// The database only ever stores kilograms. That is deliberate — one canonical
/// unit is what keeps volume sums, history and future personal records
/// comparable for a user who switches — so this enum is the single boundary
/// where the stored value meets the number on screen. Nothing downstream of a
/// conversion may be written back to a weight column.
enum WeightUnit {
  kg('kg', 1),
  lb('lb', 2.2046226218487757);

  const WeightUnit(this.symbol, this.perKilogram);

  /// Lowercase; screens uppercase it where the design calls for that.
  final String symbol;

  /// How many of this unit make one kilogram.
  final double perKilogram;

  double fromKilograms(double kilograms) => kilograms * perKilogram;

  double toKilograms(double value) => value / perKilogram;

  /// Resolves a stored preference by [name], falling back to kilograms.
  ///
  /// Never throws on an unknown value: a settings row written by a build that
  /// knew a unit this one does not has to degrade to a working default, not
  /// take the app down at startup.
  static WeightUnit byName(String? name) {
    for (final unit in values) {
      if (unit.name == name) return unit;
    }
    return kg;
  }
}
