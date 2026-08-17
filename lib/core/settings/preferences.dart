import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/repositories/repositories.dart';
import 'weight_unit.dart';

// Anything that reads the unit preference needs the enum to do something with
// it, so the two travel together.
export 'weight_unit.dart';

/// Device-local preferences that change how the app behaves.
///
/// Not synced, and deliberately not a synced entity: these are facts about
/// this installation. Someone who logs in pounds on their phone may well read
/// kilograms on a tablet, and pushing the choice to the backend would make one
/// device silently overwrite the other.
class Preferences {
  const Preferences({
    this.weightUnit = WeightUnit.kg,
    this.defaultRestSeconds = defaultRest,
    this.timerSound = true,
  });

  /// The rest a routine slot starts life with, matching the column default in
  /// `routine_exercises`.
  static const int defaultRest = 90;

  final WeightUnit weightUnit;

  /// Rest pre-filled into a new routine slot. Editing a slot still overrides
  /// it — this is the starting point, not a cap.
  final int defaultRestSeconds;

  final bool timerSound;

  Preferences copyWith({
    WeightUnit? weightUnit,
    int? defaultRestSeconds,
    bool? timerSound,
  }) {
    return Preferences(
      weightUnit: weightUnit ?? this.weightUnit,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      timerSound: timerSound ?? this.timerSound,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.weightUnit == weightUnit &&
      other.defaultRestSeconds == defaultRestSeconds &&
      other.timerSound == timerSound;

  @override
  int get hashCode => Object.hash(weightUnit, defaultRestSeconds, timerSound);
}

/// Reads every preference off disk in one go.
///
/// Called from `bootstrapPwr` before the first frame. Doing it up front is what
/// lets the rest of the app read preferences synchronously: a set row cannot
/// afford to resolve a future before it can decide whether to print `kg`.
Future<Preferences> loadPreferences(SettingsRepository settings) async {
  final unit = await settings.getString(SettingsRepository.weightUnit);
  final rest = await settings.getInt(SettingsRepository.defaultRestSeconds);
  final sound = await settings.getFlag(
    SettingsRepository.timerSound,
    orElse: true,
  );

  return Preferences(
    weightUnit: WeightUnit.byName(unit),
    defaultRestSeconds: rest ?? Preferences.defaultRest,
    timerSound: sound,
  );
}

/// Holds the preferences and writes changes through.
class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  /// Installs what was read at startup.
  ///
  /// Called once from `bootstrapPwr`, before `runApp`, so no frame is ever
  /// painted with the defaults this notifier is built with.
  void hydrate(Preferences preferences) => state = preferences;

  /// Each setter moves the state first and persists after.
  ///
  /// The same reasoning as checking off a set: the write is local and cannot
  /// meaningfully fail, and a switch that waits on SQLite before it moves feels
  /// broken. A failed write costs the user one re-tap next launch, which is
  /// cheaper than a laggy control on every tap.
  Future<void> setWeightUnit(WeightUnit unit) {
    state = state.copyWith(weightUnit: unit);
    return _settings.setString(SettingsRepository.weightUnit, unit.name);
  }

  Future<void> setDefaultRestSeconds(int seconds) {
    state = state.copyWith(defaultRestSeconds: seconds);
    return _settings.setInt(SettingsRepository.defaultRestSeconds, seconds);
  }

  Future<void> setTimerSound({required bool enabled}) {
    state = state.copyWith(timerSound: enabled);
    return _settings.setFlag(SettingsRepository.timerSound, value: enabled);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );

/// The unit to render loads in.
///
/// A provider of its own so a widget that only prints a weight rebuilds when
/// the unit changes and not when the rest timer's sound is toggled.
final weightUnitProvider = Provider<WeightUnit>(
  (ref) => ref.watch(preferencesProvider.select((p) => p.weightUnit)),
);
