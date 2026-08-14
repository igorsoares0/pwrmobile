import '../../core/database/enums.dart';
import '../../l10n/app_localizations.dart';

/// Localised names for the database enums.
///
/// Kept out of `enums.dart` so the data layer stays free of any dependency on
/// the widget tree, and exhaustive rather than map-backed so that adding an
/// enum value fails to compile until it has been translated.
extension MuscleGroupRegionLabel on MuscleGroupRegion {
  String label(AppLocalizations l10n) => switch (this) {
    MuscleGroupRegion.chest => l10n.regionChest,
    MuscleGroupRegion.back => l10n.regionBack,
    MuscleGroupRegion.shoulders => l10n.regionShoulders,
    MuscleGroupRegion.arms => l10n.regionArms,
    MuscleGroupRegion.legs => l10n.regionLegs,
    MuscleGroupRegion.core => l10n.regionCore,
    MuscleGroupRegion.other => l10n.regionOther,
  };
}

extension MuscleGroupLabel on MuscleGroup {
  String label(AppLocalizations l10n) => switch (this) {
    MuscleGroup.chest => l10n.muscleChest,
    MuscleGroup.back => l10n.muscleBack,
    MuscleGroup.shoulders => l10n.muscleShoulders,
    MuscleGroup.biceps => l10n.muscleBiceps,
    MuscleGroup.triceps => l10n.muscleTriceps,
    MuscleGroup.forearms => l10n.muscleForearms,
    MuscleGroup.quads => l10n.muscleQuads,
    MuscleGroup.hamstrings => l10n.muscleHamstrings,
    MuscleGroup.glutes => l10n.muscleGlutes,
    MuscleGroup.calves => l10n.muscleCalves,
    MuscleGroup.core => l10n.muscleCore,
    MuscleGroup.cardio => l10n.muscleCardio,
    MuscleGroup.other => l10n.muscleOther,
  };
}

extension EquipmentLabel on Equipment {
  String label(AppLocalizations l10n) => switch (this) {
    Equipment.barbell => l10n.equipmentBarbell,
    Equipment.dumbbell => l10n.equipmentDumbbell,
    Equipment.machine => l10n.equipmentMachine,
    Equipment.cable => l10n.equipmentCable,
    Equipment.bodyweight => l10n.equipmentBodyweight,
    Equipment.kettlebell => l10n.equipmentKettlebell,
    Equipment.band => l10n.equipmentBand,
    Equipment.other => l10n.equipmentOther,
  };
}
