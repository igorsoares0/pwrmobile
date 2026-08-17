// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PWR';

  @override
  String get homeGreeting => 'Good session.';

  @override
  String homeWeekLabel(String weekday, int week) {
    return '$weekday · week $week';
  }

  @override
  String get homeStatWorkouts => 'workouts\nthis week';

  @override
  String get homeStatVolume => 'total\nvolume';

  @override
  String get homeStatSets => 'sets\nthis week';

  @override
  String get homeRoutinesTitle => 'Your routines';

  @override
  String homeRoutinesCounter(int used, int limit) {
    return '$used/$limit on free';
  }

  @override
  String homeRoutinesUnlimited(int used) {
    return '$used routines';
  }

  @override
  String homeRoutineSubtitle(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'no exercises',
    );
    return '$_temp0 · ~$minutes min';
  }

  @override
  String get homeNewRoutine => 'New routine';

  @override
  String get homeNewRoutineLocked => 'Free plan limit reached';

  @override
  String get homeNewRoutineHint => 'Build your first one';

  @override
  String get homeEmptyTitle => 'No routines yet.';

  @override
  String get homeEmptyBody =>
      'A routine is a list of exercises you repeat. Build one and every session after this takes three taps.';

  @override
  String get homeEmptyAction => 'Create a routine';

  @override
  String get homeLibrary => 'Exercise library';

  @override
  String homeLibraryCount(int count) {
    return '$count exercises';
  }

  @override
  String get homeResumeWorkout => 'Workout in progress';

  @override
  String get homeResumeAction => 'Resume';

  @override
  String get unitTonnesShort => 't';

  @override
  String get unitKilogramsShort => 'kg';

  @override
  String get libraryTitle => 'Exercise library';

  @override
  String get librarySearchHint => 'Search exercise…';

  @override
  String get libraryFilterAll => 'All';

  @override
  String librarySection(String region, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$region · $_temp0';
  }

  @override
  String get libraryCreateCustom => 'Create your own exercise';

  @override
  String get libraryCreateCustomHint => 'Anything the library is missing';

  @override
  String libraryEmptySearch(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String get libraryEmptySearchBody =>
      'Check the spelling, or add it as your own exercise.';

  @override
  String get libraryCustomBadge => 'Yours';

  @override
  String get createExerciseTitle => 'New exercise';

  @override
  String get createExerciseNameLabel => 'Name';

  @override
  String get createExerciseNameHint => 'e.g. Reverse hack squat';

  @override
  String get createExerciseMuscleLabel => 'Primary muscle';

  @override
  String get createExerciseEquipmentLabel => 'Equipment';

  @override
  String get createExerciseSave => 'Save exercise';

  @override
  String get createExerciseNameRequired => 'Give it a name first.';

  @override
  String get regionChest => 'Chest';

  @override
  String get regionBack => 'Back';

  @override
  String get regionShoulders => 'Shoulders';

  @override
  String get regionArms => 'Arms';

  @override
  String get regionLegs => 'Legs';

  @override
  String get regionCore => 'Core';

  @override
  String get regionOther => 'Other';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get muscleOther => 'Other';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentBodyweight => 'Bodyweight';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentBand => 'Band';

  @override
  String get equipmentOther => 'Other';

  @override
  String get routineNew => 'New routine';

  @override
  String get routineEdit => 'Edit routine';

  @override
  String get routineDefaultName => 'New routine';

  @override
  String get routineNameLabel => 'Routine name';

  @override
  String get routineNameHint => 'e.g. Push A';

  @override
  String get routineFocusLabel => 'Focus';

  @override
  String get routineFocusHint => 'e.g. Chest & triceps';

  @override
  String routineExercisesHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'exercises · $count',
      one: 'exercises · 1',
      zero: 'exercises',
    );
    return '$_temp0';
  }

  @override
  String get routineReorderHint => 'drag to reorder';

  @override
  String get routineAddExercise => 'Add exercise';

  @override
  String get routineNoExercises => 'No exercises yet.';

  @override
  String get routineNoExercisesBody =>
      'Add the movements you do, in the order you do them.';

  @override
  String routineSlotSummary(int sets, int rest) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    return '$_temp0 · rest ${rest}s';
  }

  @override
  String routineSlotSummaryWithReps(int sets, int reps, int rest) {
    return '$sets×$reps · rest ${rest}s';
  }

  @override
  String get routineSupersetMarker => 'superset with the next';

  @override
  String get routineSupersetToggle => 'Chain with the next exercise';

  @override
  String get routineDone => 'Done';

  @override
  String get routineDelete => 'Delete routine';

  @override
  String get routineDeleteConfirm =>
      'Delete this routine? Workouts you already logged from it are kept.';

  @override
  String routineLimitTitle(int limit) {
    return 'Free plan allows $limit routines.';
  }

  @override
  String get routineLimitBody =>
      'Delete one to make room, or go PRO for unlimited routines.';

  @override
  String get slotSets => 'Sets';

  @override
  String get slotReps => 'Target reps';

  @override
  String get slotRepsAny => 'Any';

  @override
  String get slotRest => 'Rest';

  @override
  String slotRestSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get slotRemove => 'Remove from routine';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String workoutInProgress(int current, int total) {
    return 'in progress · ex. $current of $total';
  }

  @override
  String workoutProgressSets(int done, int total) {
    return 'in progress · $done of $total sets';
  }

  @override
  String workoutSupersetOf(String letter) {
    return 'superset $letter';
  }

  @override
  String get workoutTotal => 'total';

  @override
  String get workoutColSet => 'set';

  @override
  String get workoutColWeight => 'kg';

  @override
  String get workoutColReps => 'reps';

  @override
  String get workoutColDone => 'ok';

  @override
  String get workoutSetWarmup => 'W';

  @override
  String get workoutSetFailure => 'F';

  @override
  String get workoutSetDrop => 'D';

  @override
  String get workoutSuperset => 'superset';

  @override
  String workoutPrevious(int sets, int reps, String weight, String unit) {
    return 'prev $sets×$reps · $weight$unit';
  }

  @override
  String get workoutNoPrevious => 'first time';

  @override
  String workoutNext(String name) {
    return 'next · $name';
  }

  @override
  String get workoutLastExercise => 'last exercise';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutRest => 'rest';

  @override
  String get workoutRestPaused => 'paused';

  @override
  String get workoutRestDone => 'done';

  @override
  String get workoutRestStart => 'Start';

  @override
  String get workoutRestPause => 'Pause';

  @override
  String get workoutRestResume => 'Resume';

  @override
  String get workoutRestSkip => 'Skip';

  @override
  String get workoutRestAdd => '+30s';

  @override
  String get workoutFinish => 'Finish workout';

  @override
  String workoutFinishConfirm(int done, int planned) {
    return 'Finish this workout? $done of $planned sets are checked off.';
  }

  @override
  String get workoutFinishAction => 'Finish';

  @override
  String get workoutDiscard => 'Discard workout';

  @override
  String get workoutDiscardAction => 'Discard';

  @override
  String workoutDiscardConfirm(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'Discard this workout? $done checked-off sets will be lost.',
      one: 'Discard this workout? 1 checked-off set will be lost.',
      zero: 'This workout has no sets checked off yet. Discard it?',
    );
    return '$_temp0';
  }

  @override
  String get workoutEmpty => 'This workout has no exercises.';

  @override
  String get workoutEmptyBody => 'Add one from the library to get going.';

  @override
  String get workoutNoSession => 'No workout in progress.';

  @override
  String summaryComplete(int minutes) {
    return 'workout complete · $minutes min';
  }

  @override
  String summaryTitle(String name) {
    return '$name logged.';
  }

  @override
  String get summaryTitleNoRoutine => 'Workout logged.';

  @override
  String get summaryVolumeCaption => 'total volume';

  @override
  String summaryVsPrevious(String delta) {
    return '$delta vs. last time';
  }

  @override
  String get summaryFirstOnRoutine => 'first time on this routine';

  @override
  String get summaryStatSets => 'sets';

  @override
  String get summaryStatExercises => 'exercises';

  @override
  String get summaryStatDuration => 'minutes';

  @override
  String get summaryBestToday => 'your best today';

  @override
  String summaryBestSet(String weight, String unit, int reps) {
    return '$weight$unit × $reps';
  }

  @override
  String summaryBodyweightSet(int reps) {
    return '$reps reps';
  }

  @override
  String get summaryNothingLogged => 'Nothing was checked off.';

  @override
  String get summaryNothingLoggedBody =>
      'The session is saved, but no sets were recorded against it.';

  @override
  String get summaryClose => 'Done';

  @override
  String get summaryMissing => 'That workout is gone.';

  @override
  String get historyTitle => 'History';

  @override
  String historyMonth(String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$month · $_temp0';
  }

  @override
  String historyRowSubtitle(String day, int sets, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    return '$day · $_temp0 · $minutes min';
  }

  @override
  String get historyFreestyle => 'Freestyle workout';

  @override
  String get historyEmpty => 'No workouts yet.';

  @override
  String get historyEmptyBody =>
      'Finish a session and it lands here, with everything you lifted.';

  @override
  String get navWorkout => 'training';

  @override
  String get navHistory => 'history';

  @override
  String get navBody => 'body';

  @override
  String get navProfile => 'profile';

  @override
  String get shellSessionResting => 'resting';

  @override
  String get shellSessionActive => 'in progress';

  @override
  String shellSessionStale(String when) {
    return 'open since $when';
  }

  @override
  String get shellSessionResume => 'Back to the workout';

  @override
  String get navStartWorkout => 'Start a workout';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get bodyTitle => 'Body';

  @override
  String get profileTitle => 'Profile';

  @override
  String get bodyCurrentWeight => 'current weight';

  @override
  String get bodyNoBaseline => 'first entry';

  @override
  String bodyDeltaWeeks(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
      zero: 'under a week',
    );
    return 'in $_temp0';
  }

  @override
  String get bodyLogWeight => 'Log weight';

  @override
  String get bodyLogTitle => 'Weigh-in';

  @override
  String get bodyLogDate => 'Date';

  @override
  String get bodyLogToday => 'Today';

  @override
  String get bodyLogSave => 'Save';

  @override
  String get bodyLogDelete => 'Delete this entry';

  @override
  String get bodyHistory => 'History';

  @override
  String get bodyEmptyHeadline => 'No weigh-ins yet.';

  @override
  String get bodyEmptyBody =>
      'One number a week is enough. It is the line under every other number in the app — volume means something different at 74 kg than at 82.';

  @override
  String get bodyMeasurements => 'Measurements';

  @override
  String get bodyMeasurementsLocked =>
      'Chest, waist, arm and thigh — plus progress photos — are part of PRO.';

  @override
  String get bodyChest => 'Chest';

  @override
  String get bodyWaist => 'Waist';

  @override
  String get bodyArm => 'Arm';

  @override
  String get bodyThigh => 'Thigh';

  @override
  String get bodyLocked => 'PRO';

  @override
  String get profileAccountTitle => 'This device';

  @override
  String get profileAccountSubtitle => 'free plan';

  @override
  String get profileAccountNote =>
      'Everything you log is stored here. Accounts and cloud sync arrive in a later release.';

  @override
  String get profileSectionTraining => 'Training';

  @override
  String get profileWeightUnit => 'Weight unit';

  @override
  String get profileWeightUnitSheet => 'Show loads in';

  @override
  String get profileDefaultRest => 'Default rest';

  @override
  String get profileDefaultRestSheet => 'Rest for a new exercise';

  @override
  String get profileDefaultRestNote =>
      'Applies to exercises you add from now on. Each one can still be changed individually.';

  @override
  String get profileTimerSound => 'Rest timer alert';

  @override
  String get profileSectionData => 'Data';

  @override
  String get profileExport => 'Export training log (CSV)';

  @override
  String get profileExportSubtitle => 'every completed set';

  @override
  String get profileExportEmpty => 'No finished workouts to export yet.';

  @override
  String get profileExportFailed => 'Could not build the export.';

  @override
  String profileExportSubject(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return 'PWR · $_temp0';
  }

  @override
  String get onboardingHeadline => 'Log your session in';

  @override
  String get onboardingHeadlineAccent => 'three taps.';

  @override
  String get onboardingBody =>
      'Load, reps and rest. No feed, no distractions — just what you lifted.';

  @override
  String get onboardingStep1 => 'Pick a routine';

  @override
  String get onboardingStep1Body => 'Up to 3 on the free plan.';

  @override
  String get onboardingStep2 => 'Check off each set';

  @override
  String get onboardingStep2Body => 'It fills in what you lifted last time.';

  @override
  String get onboardingStep3 => 'Watch it add up';

  @override
  String get onboardingStep3Body => 'Volume and history for every session.';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingOffline =>
      'Works with no signal. Everything stays on this device.';

  @override
  String get shareAction => 'Share';

  @override
  String get sharePreviewTitle => 'Share this workout';

  @override
  String get shareConfirm => 'Share image';

  @override
  String get shareCardSets => 'sets';

  @override
  String get shareCardMinutes => 'min';

  @override
  String get shareCardBest => 'best set';

  @override
  String get shareCardFreestyle => 'Workout';

  @override
  String shareSubject(String routine, String volume, String unit) {
    return '$routine · $volume $unit';
  }

  @override
  String get shareFailed => 'Could not build the image.';
}
