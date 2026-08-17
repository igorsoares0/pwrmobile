import '../../core/database/repositories/repositories.dart';

/// A run of exercises the user performs as one unit.
///
/// Either a single exercise, or a superset: two or more adjacent exercises
/// sharing a group id, done back to back with the rest taken once at the end.
class WorkoutBlock {
  const WorkoutBlock({required this.members, this.letter});

  final List<WorkoutExerciseDetail> members;

  /// `A`, `B`, `C`… naming this superset, or null for a lone exercise.
  ///
  /// Lettered rather than numbered because the members are already numbered
  /// inside it: the second movement of the first superset is `A2`, which is
  /// how it is written on paper.
  final String? letter;

  bool get isSuperset => members.length > 1;

  /// `A1`, `A2`… for a superset member; null when the block is one exercise
  /// and the label would say nothing.
  String? labelFor(int index) => letter == null ? null : '$letter${index + 1}';
}

/// Groups a session's exercises into the units they are performed in.
///
/// Adjacency is what makes a chain, exactly as in the routine builder: two
/// neighbours belong together when they share a non-null `supersetGroup`. The
/// group id alone is not enough — an id repeated in two places in the list
/// describes two chains, not one interleaved one.
List<WorkoutBlock> blocksOf(List<WorkoutExerciseDetail> exercises) {
  final blocks = <WorkoutBlock>[];
  var letter = 0;

  var index = 0;
  while (index < exercises.length) {
    final group = exercises[index].entry.supersetGroup;

    var end = index + 1;
    if (group != null) {
      while (end < exercises.length &&
          exercises[end].entry.supersetGroup == group) {
        end++;
      }
    }

    final members = exercises.sublist(index, end);
    blocks.add(
      WorkoutBlock(
        members: members,
        // A group id shared with nobody is not a superset, whatever the
        // database says — it can be left behind by removing the other half of
        // a pair mid-workout.
        letter: members.length > 1
            ? String.fromCharCode(65 + letter++)
            : null,
      ),
    );

    index = end;
  }

  return blocks;
}
