import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// Starts workouts, resuming rather than refusing when one is already open.
class WorkoutLauncher {
  const WorkoutLauncher(this._workouts);

  final WorkoutRepository _workouts;

  /// Returns the session to open for [routineId].
  ///
  /// The repository throws if a workout is already in progress, which is the
  /// right default for a data layer but the wrong behaviour for a tap: the user
  /// pressing a routine while another session is open almost always means
  /// "take me back to my workout". Resuming beats an error dialog.
  Future<WorkoutSession> startOrResume(String routineId) async {
    final active = await _workouts.activeSession();
    if (active != null) return active;
    return _workouts.startFromRoutine(routineId);
  }

  /// Returns the session to open for a workout with no routine behind it.
  ///
  /// Same resumption rule: the centre button while a workout is open means
  /// "back to my workout", not "throw away what I am doing and start over".
  Future<WorkoutSession> startOrResumeFree() async {
    final active = await _workouts.activeSession();
    if (active != null) return active;
    return _workouts.startEmpty();
  }
}

final workoutLauncherProvider = Provider<WorkoutLauncher>(
  (ref) => WorkoutLauncher(ref.watch(workoutRepositoryProvider)),
);
