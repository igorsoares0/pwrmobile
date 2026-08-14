import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// Creating and abandoning routines.
///
/// The builder persists every keystroke, so a routine has to exist before it
/// can be edited. That trades a draft the user could lose for a row that might
/// be abandoned — [discardIfUntouched] cleans up the latter.
class RoutineCreation {
  const RoutineCreation(this._routines);

  final RoutineRepository _routines;

  /// Creates an empty routine to edit.
  Future<Routine> create(String defaultName) =>
      _routines.create(name: defaultName);

  /// Removes a routine the user opened and then walked away from.
  ///
  /// "Untouched" means the name is still the default and nothing was added.
  /// Anything else — a rename, one exercise — is intent, and is kept.
  Future<bool> discardIfUntouched(String routineId, String defaultName) async {
    final routine = await _routines.findById(routineId);
    if (routine == null) return false;
    if (routine.name.trim() != defaultName) return false;
    if ((routine.focus ?? '').trim().isNotEmpty) return false;

    final slots = await _routines.exercisesOf(routineId);
    if (slots.isNotEmpty) return false;

    await _routines.delete(routineId);
    return true;
  }
}

final routineCreationProvider = Provider<RoutineCreation>(
  (ref) => RoutineCreation(ref.watch(routineRepositoryProvider)),
);
