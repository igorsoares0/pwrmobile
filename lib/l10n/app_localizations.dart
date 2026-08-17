import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// The product name. Never translated.
  ///
  /// In en, this message translates to:
  /// **'PWR'**
  String get appName;

  /// Home headline. Gains the user's name once accounts exist in phase 2.
  ///
  /// In en, this message translates to:
  /// **'Good session.'**
  String get homeGreeting;

  /// Overline above the home greeting.
  ///
  /// In en, this message translates to:
  /// **'{weekday} · week {week}'**
  String homeWeekLabel(String weekday, int week);

  /// Caption under the weekly workout count. The line break is intentional.
  ///
  /// In en, this message translates to:
  /// **'workouts\nthis week'**
  String get homeStatWorkouts;

  /// No description provided for @homeStatVolume.
  ///
  /// In en, this message translates to:
  /// **'total\nvolume'**
  String get homeStatVolume;

  /// No description provided for @homeStatSets.
  ///
  /// In en, this message translates to:
  /// **'sets\nthis week'**
  String get homeStatSets;

  /// No description provided for @homeRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your routines'**
  String get homeRoutinesTitle;

  /// No description provided for @homeRoutinesCounter.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} on free'**
  String homeRoutinesCounter(int used, int limit);

  /// No description provided for @homeRoutinesUnlimited.
  ///
  /// In en, this message translates to:
  /// **'{used} routines'**
  String homeRoutinesUnlimited(int used);

  /// No description provided for @homeRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no exercises} =1{1 exercise} other{{count} exercises}} · ~{minutes} min'**
  String homeRoutineSubtitle(int count, int minutes);

  /// No description provided for @homeNewRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get homeNewRoutine;

  /// No description provided for @homeNewRoutineLocked.
  ///
  /// In en, this message translates to:
  /// **'Free plan limit reached'**
  String get homeNewRoutineLocked;

  /// No description provided for @homeNewRoutineHint.
  ///
  /// In en, this message translates to:
  /// **'Build your first one'**
  String get homeNewRoutineHint;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No routines yet.'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A routine is a list of exercises you repeat. Build one and every session after this takes three taps.'**
  String get homeEmptyBody;

  /// No description provided for @homeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Create a routine'**
  String get homeEmptyAction;

  /// No description provided for @homeLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise library'**
  String get homeLibrary;

  /// No description provided for @homeLibraryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String homeLibraryCount(int count);

  /// No description provided for @homeResumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get homeResumeWorkout;

  /// No description provided for @homeResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResumeAction;

  /// No description provided for @unitTonnesShort.
  ///
  /// In en, this message translates to:
  /// **'t'**
  String get unitTonnesShort;

  /// No description provided for @unitKilogramsShort.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKilogramsShort;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise library'**
  String get libraryTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercise…'**
  String get librarySearchHint;

  /// No description provided for @libraryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryFilterAll;

  /// No description provided for @librarySection.
  ///
  /// In en, this message translates to:
  /// **'{region} · {count, plural, =1{1 exercise} other{{count} exercises}}'**
  String librarySection(String region, int count);

  /// No description provided for @libraryCreateCustom.
  ///
  /// In en, this message translates to:
  /// **'Create your own exercise'**
  String get libraryCreateCustom;

  /// No description provided for @libraryCreateCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the library is missing'**
  String get libraryCreateCustomHint;

  /// No description provided for @libraryEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String libraryEmptySearch(String query);

  /// No description provided for @libraryEmptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or add it as your own exercise.'**
  String get libraryEmptySearchBody;

  /// No description provided for @libraryCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get libraryCustomBadge;

  /// No description provided for @createExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get createExerciseTitle;

  /// No description provided for @createExerciseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get createExerciseNameLabel;

  /// No description provided for @createExerciseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Reverse hack squat'**
  String get createExerciseNameHint;

  /// No description provided for @createExerciseMuscleLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary muscle'**
  String get createExerciseMuscleLabel;

  /// No description provided for @createExerciseEquipmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get createExerciseEquipmentLabel;

  /// No description provided for @createExerciseSave.
  ///
  /// In en, this message translates to:
  /// **'Save exercise'**
  String get createExerciseSave;

  /// No description provided for @createExerciseNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name first.'**
  String get createExerciseNameRequired;

  /// No description provided for @regionChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get regionChest;

  /// No description provided for @regionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get regionBack;

  /// No description provided for @regionShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get regionShoulders;

  /// No description provided for @regionArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get regionArms;

  /// No description provided for @regionLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get regionLegs;

  /// No description provided for @regionCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get regionCore;

  /// No description provided for @regionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get regionOther;

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// No description provided for @muscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get muscleQuads;

  /// No description provided for @muscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// No description provided for @muscleCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// No description provided for @muscleCardio.
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get muscleCardio;

  /// No description provided for @muscleOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get muscleOther;

  /// No description provided for @equipmentBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipmentBarbell;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get equipmentMachine;

  /// No description provided for @equipmentCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get equipmentCable;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentKettlebell.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// No description provided for @equipmentBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get equipmentBand;

  /// No description provided for @equipmentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get equipmentOther;

  /// No description provided for @routineNew.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get routineNew;

  /// No description provided for @routineEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get routineEdit;

  /// No description provided for @routineDefaultName.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get routineDefaultName;

  /// No description provided for @routineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineNameLabel;

  /// No description provided for @routineNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push A'**
  String get routineNameHint;

  /// No description provided for @routineFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get routineFocusLabel;

  /// No description provided for @routineFocusHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chest & triceps'**
  String get routineFocusHint;

  /// No description provided for @routineExercisesHeader.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{exercises} =1{exercises · 1} other{exercises · {count}}}'**
  String routineExercisesHeader(int count);

  /// No description provided for @routineReorderHint.
  ///
  /// In en, this message translates to:
  /// **'drag to reorder'**
  String get routineReorderHint;

  /// No description provided for @routineAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get routineAddExercise;

  /// No description provided for @routineNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet.'**
  String get routineNoExercises;

  /// No description provided for @routineNoExercisesBody.
  ///
  /// In en, this message translates to:
  /// **'Add the movements you do, in the order you do them.'**
  String get routineNoExercisesBody;

  /// No description provided for @routineSlotSummary.
  ///
  /// In en, this message translates to:
  /// **'{sets, plural, =1{1 set} other{{sets} sets}} · rest {rest}s'**
  String routineSlotSummary(int sets, int rest);

  /// No description provided for @routineSlotSummaryWithReps.
  ///
  /// In en, this message translates to:
  /// **'{sets}×{reps} · rest {rest}s'**
  String routineSlotSummaryWithReps(int sets, int reps, int rest);

  /// No description provided for @routineSupersetMarker.
  ///
  /// In en, this message translates to:
  /// **'superset with the next'**
  String get routineSupersetMarker;

  /// No description provided for @routineSupersetToggle.
  ///
  /// In en, this message translates to:
  /// **'Chain with the next exercise'**
  String get routineSupersetToggle;

  /// No description provided for @routineDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get routineDone;

  /// No description provided for @routineDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get routineDelete;

  /// No description provided for @routineDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this routine? Workouts you already logged from it are kept.'**
  String get routineDeleteConfirm;

  /// No description provided for @routineLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows {limit} routines.'**
  String routineLimitTitle(int limit);

  /// No description provided for @routineLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Delete one to make room, or go PRO for unlimited routines.'**
  String get routineLimitBody;

  /// No description provided for @slotSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get slotSets;

  /// No description provided for @slotReps.
  ///
  /// In en, this message translates to:
  /// **'Target reps'**
  String get slotReps;

  /// No description provided for @slotRepsAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get slotRepsAny;

  /// No description provided for @slotRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get slotRest;

  /// No description provided for @slotRestSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String slotRestSeconds(int seconds);

  /// No description provided for @slotRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from routine'**
  String get slotRemove;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress · ex. {current} of {total}'**
  String workoutInProgress(int current, int total);

  /// No description provided for @workoutProgressSets.
  ///
  /// In en, this message translates to:
  /// **'in progress · {done} of {total} sets'**
  String workoutProgressSets(int done, int total);

  /// No description provided for @workoutSupersetOf.
  ///
  /// In en, this message translates to:
  /// **'superset {letter}'**
  String workoutSupersetOf(String letter);

  /// No description provided for @workoutTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get workoutTotal;

  /// No description provided for @workoutColSet.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get workoutColSet;

  /// No description provided for @workoutColWeight.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get workoutColWeight;

  /// No description provided for @workoutColReps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get workoutColReps;

  /// No description provided for @workoutColDone.
  ///
  /// In en, this message translates to:
  /// **'ok'**
  String get workoutColDone;

  /// No description provided for @workoutSetWarmup.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get workoutSetWarmup;

  /// No description provided for @workoutSetFailure.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get workoutSetFailure;

  /// No description provided for @workoutSetDrop.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get workoutSetDrop;

  /// No description provided for @workoutSuperset.
  ///
  /// In en, this message translates to:
  /// **'superset'**
  String get workoutSuperset;

  /// No description provided for @workoutPrevious.
  ///
  /// In en, this message translates to:
  /// **'prev {sets}×{reps} · {weight}{unit}'**
  String workoutPrevious(int sets, int reps, String weight, String unit);

  /// No description provided for @workoutNoPrevious.
  ///
  /// In en, this message translates to:
  /// **'first time'**
  String get workoutNoPrevious;

  /// No description provided for @workoutNext.
  ///
  /// In en, this message translates to:
  /// **'next · {name}'**
  String workoutNext(String name);

  /// No description provided for @workoutLastExercise.
  ///
  /// In en, this message translates to:
  /// **'last exercise'**
  String get workoutLastExercise;

  /// No description provided for @workoutAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get workoutAddSet;

  /// No description provided for @workoutRest.
  ///
  /// In en, this message translates to:
  /// **'rest'**
  String get workoutRest;

  /// No description provided for @workoutRestPaused.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get workoutRestPaused;

  /// No description provided for @workoutRestDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get workoutRestDone;

  /// No description provided for @workoutRestStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workoutRestStart;

  /// No description provided for @workoutRestPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get workoutRestPause;

  /// No description provided for @workoutRestResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get workoutRestResume;

  /// No description provided for @workoutRestSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get workoutRestSkip;

  /// No description provided for @workoutRestAdd.
  ///
  /// In en, this message translates to:
  /// **'+30s'**
  String get workoutRestAdd;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinish;

  /// No description provided for @workoutFinishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Finish this workout? {done} of {planned} sets are checked off.'**
  String workoutFinishConfirm(int done, int planned);

  /// No description provided for @workoutFinishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinishAction;

  /// No description provided for @workoutDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get workoutDiscard;

  /// No description provided for @workoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'This workout has no exercises.'**
  String get workoutEmpty;

  /// No description provided for @workoutEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add one from the library to get going.'**
  String get workoutEmptyBody;

  /// No description provided for @workoutNoSession.
  ///
  /// In en, this message translates to:
  /// **'No workout in progress.'**
  String get workoutNoSession;

  /// No description provided for @summaryComplete.
  ///
  /// In en, this message translates to:
  /// **'workout complete · {minutes} min'**
  String summaryComplete(int minutes);

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} logged.'**
  String summaryTitle(String name);

  /// No description provided for @summaryTitleNoRoutine.
  ///
  /// In en, this message translates to:
  /// **'Workout logged.'**
  String get summaryTitleNoRoutine;

  /// No description provided for @summaryVolumeCaption.
  ///
  /// In en, this message translates to:
  /// **'total volume'**
  String get summaryVolumeCaption;

  /// No description provided for @summaryVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs. last time'**
  String summaryVsPrevious(String delta);

  /// No description provided for @summaryFirstOnRoutine.
  ///
  /// In en, this message translates to:
  /// **'first time on this routine'**
  String get summaryFirstOnRoutine;

  /// No description provided for @summaryStatSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get summaryStatSets;

  /// No description provided for @summaryStatExercises.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get summaryStatExercises;

  /// No description provided for @summaryStatDuration.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get summaryStatDuration;

  /// No description provided for @summaryBestToday.
  ///
  /// In en, this message translates to:
  /// **'your best today'**
  String get summaryBestToday;

  /// No description provided for @summaryBestSet.
  ///
  /// In en, this message translates to:
  /// **'{weight}{unit} × {reps}'**
  String summaryBestSet(String weight, String unit, int reps);

  /// No description provided for @summaryBodyweightSet.
  ///
  /// In en, this message translates to:
  /// **'{reps} reps'**
  String summaryBodyweightSet(int reps);

  /// No description provided for @summaryNothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing was checked off.'**
  String get summaryNothingLogged;

  /// No description provided for @summaryNothingLoggedBody.
  ///
  /// In en, this message translates to:
  /// **'The session is saved, but no sets were recorded against it.'**
  String get summaryNothingLoggedBody;

  /// No description provided for @summaryClose.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get summaryClose;

  /// No description provided for @summaryMissing.
  ///
  /// In en, this message translates to:
  /// **'That workout is gone.'**
  String get summaryMissing;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} · {count, plural, =1{1 workout} other{{count} workouts}}'**
  String historyMonth(String month, int count);

  /// No description provided for @historyRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{day} · {sets, plural, =1{1 set} other{{sets} sets}} · {minutes} min'**
  String historyRowSubtitle(String day, int sets, int minutes);

  /// No description provided for @historyFreestyle.
  ///
  /// In en, this message translates to:
  /// **'Freestyle workout'**
  String get historyFreestyle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a session and it lands here, with everything you lifted.'**
  String get historyEmptyBody;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'training'**
  String get navWorkout;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'history'**
  String get navHistory;

  /// No description provided for @navBody.
  ///
  /// In en, this message translates to:
  /// **'body'**
  String get navBody;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get navProfile;

  /// No description provided for @shellSessionResting.
  ///
  /// In en, this message translates to:
  /// **'resting'**
  String get shellSessionResting;

  /// No description provided for @shellSessionActive.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get shellSessionActive;

  /// No description provided for @shellSessionStale.
  ///
  /// In en, this message translates to:
  /// **'open since {when}'**
  String shellSessionStale(String when);

  /// No description provided for @shellSessionResume.
  ///
  /// In en, this message translates to:
  /// **'Back to the workout'**
  String get shellSessionResume;

  /// No description provided for @navStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start a workout'**
  String get navStartWorkout;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutAddExercise;

  /// No description provided for @bodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get bodyTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @bodyCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'current weight'**
  String get bodyCurrentWeight;

  /// No description provided for @bodyNoBaseline.
  ///
  /// In en, this message translates to:
  /// **'first entry'**
  String get bodyNoBaseline;

  /// No description provided for @bodyDeltaWeeks.
  ///
  /// In en, this message translates to:
  /// **'in {weeks, plural, =0{under a week} =1{1 week} other{{weeks} weeks}}'**
  String bodyDeltaWeeks(int weeks);

  /// No description provided for @bodyLogWeight.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get bodyLogWeight;

  /// No description provided for @bodyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get bodyLogTitle;

  /// No description provided for @bodyLogDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bodyLogDate;

  /// No description provided for @bodyLogToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bodyLogToday;

  /// No description provided for @bodyLogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bodyLogSave;

  /// No description provided for @bodyLogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry'**
  String get bodyLogDelete;

  /// No description provided for @bodyHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bodyHistory;

  /// No description provided for @bodyEmptyHeadline.
  ///
  /// In en, this message translates to:
  /// **'No weigh-ins yet.'**
  String get bodyEmptyHeadline;

  /// No description provided for @bodyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'One number a week is enough. It is the line under every other number in the app — volume means something different at 74 kg than at 82.'**
  String get bodyEmptyBody;

  /// No description provided for @bodyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get bodyMeasurements;

  /// No description provided for @bodyMeasurementsLocked.
  ///
  /// In en, this message translates to:
  /// **'Chest, waist, arm and thigh — plus progress photos — are part of PRO.'**
  String get bodyMeasurementsLocked;

  /// No description provided for @bodyChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get bodyChest;

  /// No description provided for @bodyWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get bodyWaist;

  /// No description provided for @bodyArm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get bodyArm;

  /// No description provided for @bodyThigh.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get bodyThigh;

  /// No description provided for @bodyLocked.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get bodyLocked;

  /// No description provided for @profileAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get profileAccountTitle;

  /// No description provided for @profileAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'free plan'**
  String get profileAccountSubtitle;

  /// No description provided for @profileAccountNote.
  ///
  /// In en, this message translates to:
  /// **'Everything you log is stored here. Accounts and cloud sync arrive in a later release.'**
  String get profileAccountNote;

  /// No description provided for @profileSectionTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get profileSectionTraining;

  /// No description provided for @profileWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Weight unit'**
  String get profileWeightUnit;

  /// No description provided for @profileWeightUnitSheet.
  ///
  /// In en, this message translates to:
  /// **'Show loads in'**
  String get profileWeightUnitSheet;

  /// No description provided for @profileDefaultRest.
  ///
  /// In en, this message translates to:
  /// **'Default rest'**
  String get profileDefaultRest;

  /// No description provided for @profileDefaultRestSheet.
  ///
  /// In en, this message translates to:
  /// **'Rest for a new exercise'**
  String get profileDefaultRestSheet;

  /// No description provided for @profileDefaultRestNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to exercises you add from now on. Each one can still be changed individually.'**
  String get profileDefaultRestNote;

  /// No description provided for @profileTimerSound.
  ///
  /// In en, this message translates to:
  /// **'Rest timer alert'**
  String get profileTimerSound;

  /// No description provided for @profileSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get profileSectionData;

  /// No description provided for @profileExport.
  ///
  /// In en, this message translates to:
  /// **'Export training log (CSV)'**
  String get profileExport;

  /// No description provided for @profileExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'every completed set'**
  String get profileExportSubtitle;

  /// No description provided for @profileExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No finished workouts to export yet.'**
  String get profileExportEmpty;

  /// No description provided for @profileExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build the export.'**
  String get profileExportFailed;

  /// No description provided for @profileExportSubject.
  ///
  /// In en, this message translates to:
  /// **'PWR · {count, plural, =1{1 set} other{{count} sets}}'**
  String profileExportSubject(int count);

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Log your session in'**
  String get onboardingHeadline;

  /// No description provided for @onboardingHeadlineAccent.
  ///
  /// In en, this message translates to:
  /// **'three taps.'**
  String get onboardingHeadlineAccent;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Load, reps and rest. No feed, no distractions — just what you lifted.'**
  String get onboardingBody;

  /// No description provided for @onboardingStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick a routine'**
  String get onboardingStep1;

  /// No description provided for @onboardingStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 on the free plan.'**
  String get onboardingStep1Body;

  /// No description provided for @onboardingStep2.
  ///
  /// In en, this message translates to:
  /// **'Check off each set'**
  String get onboardingStep2;

  /// No description provided for @onboardingStep2Body.
  ///
  /// In en, this message translates to:
  /// **'It fills in what you lifted last time.'**
  String get onboardingStep2Body;

  /// No description provided for @onboardingStep3.
  ///
  /// In en, this message translates to:
  /// **'Watch it add up'**
  String get onboardingStep3;

  /// No description provided for @onboardingStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Volume and history for every session.'**
  String get onboardingStep3Body;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingOffline.
  ///
  /// In en, this message translates to:
  /// **'Works with no signal. Everything stays on this device.'**
  String get onboardingOffline;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @sharePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Share this workout'**
  String get sharePreviewTitle;

  /// No description provided for @shareConfirm.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get shareConfirm;

  /// No description provided for @shareCardSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get shareCardSets;

  /// No description provided for @shareCardMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get shareCardMinutes;

  /// No description provided for @shareCardBest.
  ///
  /// In en, this message translates to:
  /// **'best set'**
  String get shareCardBest;

  /// No description provided for @shareCardFreestyle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get shareCardFreestyle;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'{routine} · {volume} {unit}'**
  String shareSubject(String routine, String volume, String unit);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build the image.'**
  String get shareFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
