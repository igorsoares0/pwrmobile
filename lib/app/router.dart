import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/app_database.dart';
import '../features/body/body_screen.dart';
import '../features/exercises/exercise_library_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/routines/routine_builder_screen.dart';
import '../features/routines/routine_creation.dart';
import '../features/workout/workout_launcher.dart';
import '../features/workout/workout_screen.dart';
import '../features/workout/workout_summary_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/dev/design_gallery.dart';
import 'shell/pwr_shell.dart';

/// Named route paths.
///
/// The four inside the shell keep a navigation stack each. Everything else is
/// pushed over the whole screen: a workout, a summary or a picker should not
/// be competing with a tab bar for the user's thumb.
abstract final class PwrRoutes {
  static const String home = '/';
  static const String onboarding = '/welcome';
  static const String history = '/history';
  static const String body = '/body';
  static const String profile = '/profile';

  static const String library = '/library';

  /// The library opened as a picker; pops with the chosen exercise.
  static const String libraryPicker = '/library/pick';

  static const String routineBuilder = '/routines/:id';
  static const String workout = '/workout/:id';
  static const String workoutSummary = '/summary/:id';

  /// Living reference for the design system. Debug aid, not a product screen.
  static const String designGallery = '/design';

  static String routineBuilderFor(String routineId) => '/routines/$routineId';
  static String workoutFor(String sessionId) => '/workout/$sessionId';
  static String summaryFor(String sessionId) => '/summary/$sessionId';
}

/// Builds the application router.
///
/// A factory rather than a global: a `GoRouter` owns mutable navigation state
/// and a navigator key, so sharing one instance across app restarts — or
/// across tests — leaks the previous run's stack into the next. Phase 2 also
/// needs to rebuild it to install an auth redirect.
///
/// [showOnboarding] picks the starting screen. Resolved once at startup rather
/// than through a redirect, because the flag is a single local read and an
/// async redirect would make every navigation wait on it.
GoRouter createPwrRouter({bool showOnboarding = false}) {
  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: showOnboarding ? PwrRoutes.onboarding : PwrRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            PwrShell(shell: shell, onStartWorkout: () => _startFree(context)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: PwrRoutes.home,
                builder: (context, state) => HomeScreen(
                  onOpenLibrary: () => context.push(PwrRoutes.library),
                  onStartRoutine: (routineId) =>
                      _startWorkout(context, routineId),
                  onEditRoutine: (routineId) =>
                      context.push(PwrRoutes.routineBuilderFor(routineId)),
                  onResumeWorkout: (sessionId) =>
                      context.push(PwrRoutes.workoutFor(sessionId)),
                  // Switches tab rather than pushing: history is a destination
                  // now, and pushing it would leave a back arrow over a tab bar.
                  onOpenHistory: () => PwrShell.goToBranch(context, 1),
                  onCreateRoutine: () => _createAndEditRoutine(context),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: PwrRoutes.history,
                builder: (context, state) => HistoryScreen(
                  onOpenSession: (sessionId) =>
                      context.push(PwrRoutes.summaryFor(sessionId)),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: PwrRoutes.body,
                builder: (context, state) => const BodyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: PwrRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.onboarding,
        builder: (context, state) => OnboardingScreen(
          // `go`, not `push`: onboarding is done, and nothing should be able
          // to navigate back into it.
          onStart: () => context.go(PwrRoutes.home),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.library,
        builder: (context, state) =>
            ExerciseLibraryScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.libraryPicker,
        builder: (context, state) => ExerciseLibraryScreen(
          onBack: () => context.pop(),
          onSelect: (exercise) => context.pop(exercise),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.routineBuilder,
        builder: (context, state) {
          final routineId = state.pathParameters['id']!;
          return RoutineBuilderScreen(
            routineId: routineId,
            onPickExercise: () =>
                context.push<Exercise>(PwrRoutes.libraryPicker),
            onDone: () => _leaveBuilder(context, routineId),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.workout,
        builder: (context, state) {
          final sessionId = state.pathParameters['id']!;
          return WorkoutScreen(
            sessionId: sessionId,
            onPickExercise: () =>
                context.push<Exercise>(PwrRoutes.libraryPicker),
            // `pushReplacement`, not `push`: a finished workout must not be
            // reachable again by going back.
            onFinished: () =>
                context.pushReplacement(PwrRoutes.summaryFor(sessionId)),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.workoutSummary,
        builder: (context, state) => WorkoutSummaryScreen(
          sessionId: state.pathParameters['id']!,
          onClose: () => context.go(PwrRoutes.home),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: PwrRoutes.designGallery,
        builder: (context, state) => const DesignGalleryScreen(),
      ),
    ],
  );
}

/// Creates a routine and opens it for editing.
///
/// The row has to exist before the builder can run, because the builder writes
/// every keystroke through instead of holding a draft. [_leaveBuilder] removes
/// it again if the user walks away without touching anything.
Future<void> _createAndEditRoutine(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final defaultName = AppLocalizations.of(context).routineDefaultName;

  final routine = await container
      .read(routineCreationProvider)
      .create(defaultName);

  if (!context.mounted) return;
  await context.push(PwrRoutes.routineBuilderFor(routine.id));
}

Future<void> _leaveBuilder(BuildContext context, String routineId) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final defaultName = AppLocalizations.of(context).routineDefaultName;

  await container
      .read(routineCreationProvider)
      .discardIfUntouched(routineId, defaultName);

  if (!context.mounted) return;
  context.pop();
}

/// Starts a workout from a routine, or reopens the one already running.
Future<void> _startWorkout(BuildContext context, String routineId) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final session = await container
      .read(workoutLauncherProvider)
      .startOrResume(routineId);

  if (!context.mounted) return;
  await context.push(PwrRoutes.workoutFor(session.id));
}

/// The centre button: an empty session the user fills from the library.
Future<void> _startFree(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final session = await container
      .read(workoutLauncherProvider)
      .startOrResumeFree();

  if (!context.mounted) return;
  await context.push(PwrRoutes.workoutFor(session.id));
}
