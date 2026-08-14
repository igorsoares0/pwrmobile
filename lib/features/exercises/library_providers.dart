import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/enums.dart';
import '../../core/database/repositories/repositories.dart';

/// What the library is currently narrowed to.
class LibraryFilter {
  const LibraryFilter({this.region, this.query = ''});

  /// The active filter chip, or null for "all".
  final MuscleGroupRegion? region;

  final String query;

  bool get isSearching => query.trim().isNotEmpty;

  LibraryFilter copyWith({
    MuscleGroupRegion? region,
    bool clearRegion = false,
    String? query,
  }) {
    return LibraryFilter(
      region: clearRegion ? null : (region ?? this.region),
      query: query ?? this.query,
    );
  }
}

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  /// Selects a chip, or clears it when the active one is tapped again.
  void toggleRegion(MuscleGroupRegion region) {
    state = state.region == region
        ? state.copyWith(clearRegion: true)
        : state.copyWith(region: region);
  }

  void clearRegion() => state = state.copyWith(clearRegion: true);

  void search(String query) => state = state.copyWith(query: query);
}

final libraryFilterProvider =
    NotifierProvider<LibraryFilterNotifier, LibraryFilter>(
      LibraryFilterNotifier.new,
    );

/// The filtered library.
///
/// No debounce: the query runs against 98 local rows, so keystroke latency is
/// dominated by the frame, not the database. Adding one would only delay the
/// result.
final libraryProvider = StreamProvider<List<Exercise>>((ref) {
  final filter = ref.watch(libraryFilterProvider);
  return ref
      .watch(exerciseRepositoryProvider)
      .watchLibrary(region: filter.region, search: filter.query);
});

/// A run of exercises under one filter-chip heading.
class LibrarySection {
  const LibrarySection({required this.region, required this.exercises});

  final MuscleGroupRegion region;
  final List<Exercise> exercises;
}

/// The library grouped into the sections the screen renders.
///
/// Grouping happens here rather than in SQL because the coarse region is
/// derived from [MuscleGroup] in Dart — the database only knows the fine
/// grained muscle.
final librarySectionsProvider = Provider<List<LibrarySection>>((ref) {
  final exercises = ref.watch(libraryProvider).value ?? const <Exercise>[];

  final byRegion = <MuscleGroupRegion, List<Exercise>>{};
  for (final exercise in exercises) {
    byRegion.putIfAbsent(exercise.muscleGroup.region, () => []).add(exercise);
  }

  // Fixed region order, so the list does not reshuffle as the user types.
  return [
    for (final region in MuscleGroupRegion.values)
      if (byRegion[region] case final found?)
        LibrarySection(region: region, exercises: found),
  ];
});
