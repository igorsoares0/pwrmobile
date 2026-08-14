/// Enumerations persisted in the local database.
///
/// Every one of these is stored by **name**, not by index, so reordering or
/// inserting values here never corrupts existing rows. The names also travel
/// unchanged into the sync payload, which keeps the API contract readable.
library;

/// The muscle a movement primarily trains.
///
/// Deliberately finer-grained than the five filter chips in the prototype: the
/// PRO muscle heatmap and `GET /analytics/muscles` need this resolution, and
/// the UI can always collapse it via [MuscleGroupRegion].
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  core,
  cardio,
  other;

  /// The coarse bucket this muscle belongs to — what the library filter chips
  /// show.
  MuscleGroupRegion get region => switch (this) {
    MuscleGroup.chest => MuscleGroupRegion.chest,
    MuscleGroup.back => MuscleGroupRegion.back,
    MuscleGroup.shoulders => MuscleGroupRegion.shoulders,
    MuscleGroup.biceps ||
    MuscleGroup.triceps ||
    MuscleGroup.forearms => MuscleGroupRegion.arms,
    MuscleGroup.quads ||
    MuscleGroup.hamstrings ||
    MuscleGroup.glutes ||
    MuscleGroup.calves => MuscleGroupRegion.legs,
    MuscleGroup.core => MuscleGroupRegion.core,
    MuscleGroup.cardio || MuscleGroup.other => MuscleGroupRegion.other,
  };
}

/// The coarse grouping used by the exercise library filters.
enum MuscleGroupRegion { chest, back, shoulders, arms, legs, core, other }

/// What the movement is performed with.
enum Equipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  other,
}

/// The four set types from the spec.
enum SetType {
  /// Preparatory load. Excluded from volume and personal records.
  warmup,

  /// A working set.
  normal,

  /// Taken to muscular failure.
  failure,

  /// Load dropped immediately after a working set, without rest.
  dropSet;

  /// Whether this set counts towards training volume and PR detection.
  bool get countsTowardsVolume => this != SetType.warmup;
}

/// Entities that participate in synchronization.
///
/// The name is what goes in the `entity` field of a sync operation, so these
/// are snake_cased on the wire by the sync layer rather than renamed here.
enum SyncEntityType {
  exercise,
  routine,
  routineExercise,
  workoutSession,
  workoutExercise,
  workoutSet,
}

/// The two operations the sync protocol supports.
enum SyncOperationType { upsert, delete }
