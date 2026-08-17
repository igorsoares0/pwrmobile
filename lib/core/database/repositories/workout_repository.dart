import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../database_provider.dart';
import '../enums.dart';
import 'models.dart';
import 'repository.dart';

/// Sessions, the exercises inside them, and the sets that make up the product.
class WorkoutRepository extends Repository {
  const WorkoutRepository(super.db);

  /// SQL for training volume, shared by the session and history aggregates.
  ///
  /// Mirrors [WorkoutSetVolume.volume] in SQL: only completed, non-warm-up
  /// sets with both a weight and a rep count contribute. `COALESCE` keeps a
  /// session with no completed sets at `0` instead of null.
  static final Expression<double> _volume = CustomExpression<double>(
    'COALESCE(SUM(CASE WHEN workout_sets.completed = 1 '
    "AND workout_sets.type != '${SetType.warmup.name}' "
    'AND workout_sets.deleted_at IS NULL '
    'THEN workout_sets.weight * workout_sets.reps ELSE 0 END), 0)',
  );

  // --- Sessions -------------------------------------------------------------

  /// The workout in progress, if there is one.
  ///
  /// A session with no `finishedAt` is unfinished. Watching it is how the app
  /// restores a workout after the process was killed between sets — the whole
  /// point of writing to SQLite before anything else.
  Stream<WorkoutSession?> watchActiveSession() {
    return (db.select(db.workoutSessions)
          ..where((tbl) => tbl.finishedAt.isNull() & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<WorkoutSession?> activeSession() {
    return (db.select(db.workoutSessions)
          ..where((tbl) => tbl.finishedAt.isNull() & tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Starts a session from a routine, copying its slots and pre-creating the
  /// planned sets.
  ///
  /// Each planned set is seeded with the weight and reps the user hit in the
  /// same slot last time (spec §11) — the suggestion is the entire reason the
  /// app beats a notebook on the second session onwards.
  ///
  /// Throws a [StateError] if a workout is already in progress. Resuming or
  /// discarding it is a decision for the UI, not a silent one for this layer.
  Future<WorkoutSession> startFromRoutine(String routineId) async {
    return db.transaction(() async {
      await _assertNoActiveSession();

      final session = await db
          .into(db.workoutSessions)
          .insertReturning(
            WorkoutSessionsCompanion.insert(routineId: Value(routineId)),
          );

      final slots =
          await (db.select(db.routineExercises)
                ..where(
                  (tbl) =>
                      tbl.routineId.equals(routineId) & tbl.deletedAt.isNull(),
                )
                ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
              .get();

      for (final slot in slots) {
        final workoutExercise = await db
            .into(db.workoutExercises)
            .insertReturning(
              WorkoutExercisesCompanion.insert(
                sessionId: session.id,
                exerciseId: slot.exerciseId,
                position: slot.position,
                restSeconds: Value(slot.restSeconds),
                supersetGroup: Value(slot.supersetGroup),
              ),
            );

        final previous = await previousPerformance(slot.exerciseId);

        for (var number = 1; number <= slot.targetSets; number++) {
          final suggestion = previous?.suggestionFor(number);
          await db
              .into(db.workoutSets)
              .insert(
                WorkoutSetsCompanion.insert(
                  workoutExerciseId: workoutExercise.id,
                  setNumber: number,
                  weight: Value(suggestion?.weight),
                  reps: Value(suggestion?.reps ?? slot.targetReps),
                ),
              );
        }
      }

      return session;
    });
  }

  /// Starts a session with no routine behind it. Exercises are added as the
  /// user goes.
  Future<WorkoutSession> startEmpty() {
    return db.transaction(() async {
      await _assertNoActiveSession();
      return db
          .into(db.workoutSessions)
          .insertReturning(const WorkoutSessionsCompanion());
    });
  }

  /// Closes a session.
  ///
  /// Planned sets the user never checked off are left in place rather than
  /// cleaned up: every read filters on `completed`, and the gap between what
  /// was planned and what was done is real information the summary can show.
  Future<void> finish(String sessionId) {
    return db.transaction(() async {
      await (db.update(
            db.workoutSessions,
          )..where((tbl) => tbl.id.equals(sessionId) & tbl.finishedAt.isNull()))
          .write(WorkoutSessionsCompanion(finishedAt: Value(nowUtc())));
      await touch(db.workoutSessions, sessionId);
    });
  }

  /// Discards a session, for the user who started a workout by mistake.
  Future<void> discard(String sessionId) =>
      softDelete(db.workoutSessions, sessionId);

  /// Watches finished sessions, newest first, with their totals.
  Stream<List<WorkoutSessionStats>> watchHistory({int limit = 50}) {
    final setCount = db.workoutSets.id.count(
      filter: db.workoutSets.completed.equals(true),
    );
    final exerciseCount = db.workoutExercises.id.count(distinct: true);

    final query =
        db.select(db.workoutSessions).join([
            leftOuterJoin(
              db.workoutExercises,
              db.workoutExercises.sessionId.equalsExp(db.workoutSessions.id) &
                  db.workoutExercises.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.workoutSets,
              db.workoutSets.workoutExerciseId.equalsExp(
                    db.workoutExercises.id,
                  ) &
                  db.workoutSets.deletedAt.isNull(),
            ),
            // Outer, and without a `deletedAt` filter: a session started from a
            // routine the user has since deleted still has to render its name.
            leftOuterJoin(
              db.routines,
              db.routines.id.equalsExp(db.workoutSessions.routineId),
            ),
          ])
          ..addColumns([setCount, exerciseCount, _volume])
          ..where(
            db.workoutSessions.finishedAt.isNotNull() &
                db.workoutSessions.deletedAt.isNull(),
          )
          ..groupBy([db.workoutSessions.id])
          ..orderBy([OrderingTerm.desc(db.workoutSessions.startedAt)])
          ..limit(limit);

    return query.watch().map((rows) {
      return rows
          .map(
            (row) => WorkoutSessionStats(
              session: row.readTable(db.workoutSessions),
              routineName: row.readTableOrNull(db.routines)?.name,
              completedSetCount: row.read(setCount) ?? 0,
              exerciseCount: row.read(exerciseCount) ?? 0,
              volume: row.read(_volume) ?? 0,
            ),
          )
          .toList();
    });
  }

  /// Totals for the week containing [now], for the home screen.
  ///
  /// Weeks start on Monday. That is the ISO-8601 convention and matches most of
  /// the markets this ships to; a user-facing setting can override it later
  /// without changing this query.
  ///
  /// Counts sessions by when they *started*: a workout begun at 23:40 on Sunday
  /// belongs to that Sunday, not to the week it happened to end in.
  Stream<WeeklyStats> watchWeeklyStats({DateTime? now}) {
    final weekStart = startOfWeek(now ?? DateTime.now());

    final workoutCount = db.workoutSessions.id.count(distinct: true);
    final setCount = db.workoutSets.id.count(
      filter: db.workoutSets.completed.equals(true),
    );

    final query =
        db.selectOnly(db.workoutSessions).join([
            leftOuterJoin(
              db.workoutExercises,
              db.workoutExercises.sessionId.equalsExp(db.workoutSessions.id) &
                  db.workoutExercises.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.workoutSets,
              db.workoutSets.workoutExerciseId.equalsExp(
                    db.workoutExercises.id,
                  ) &
                  db.workoutSets.deletedAt.isNull(),
            ),
          ])
          ..addColumns([workoutCount, setCount, _volume])
          ..where(
            db.workoutSessions.deletedAt.isNull() &
                db.workoutSessions.finishedAt.isNotNull() &
                db.workoutSessions.startedAt.isBiggerOrEqualValue(weekStart),
          );

    return query.watch().map((rows) {
      if (rows.isEmpty) return const WeeklyStats.empty();
      final row = rows.first;
      return WeeklyStats(
        workoutCount: row.read(workoutCount) ?? 0,
        completedSetCount: row.read(setCount) ?? 0,
        volume: row.read(_volume) ?? 0,
      );
    });
  }

  /// Midnight on the Monday of [date]'s week, in local time.
  static DateTime startOfWeek(DateTime date) {
    final local = date.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    return midnight.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  /// Totals for one session, for the summary screen.
  Future<WorkoutSessionStats?> sessionStats(String sessionId) async {
    final setCount = db.workoutSets.id.count(
      filter: db.workoutSets.completed.equals(true),
    );
    final exerciseCount = db.workoutExercises.id.count(distinct: true);

    final query =
        db.select(db.workoutSessions).join([
            leftOuterJoin(
              db.workoutExercises,
              db.workoutExercises.sessionId.equalsExp(db.workoutSessions.id) &
                  db.workoutExercises.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.workoutSets,
              db.workoutSets.workoutExerciseId.equalsExp(
                    db.workoutExercises.id,
                  ) &
                  db.workoutSets.deletedAt.isNull(),
            ),
            leftOuterJoin(
              db.routines,
              db.routines.id.equalsExp(db.workoutSessions.routineId),
            ),
          ])
          ..addColumns([setCount, exerciseCount, _volume])
          ..where(
            db.workoutSessions.id.equals(sessionId) &
                db.workoutSessions.deletedAt.isNull(),
          )
          ..groupBy([db.workoutSessions.id]);

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return WorkoutSessionStats(
      session: row.readTable(db.workoutSessions),
      routineName: row.readTableOrNull(db.routines)?.name,
      completedSetCount: row.read(setCount) ?? 0,
      exerciseCount: row.read(exerciseCount) ?? 0,
      volume: row.read(_volume) ?? 0,
    );
  }

  /// The session on [routineId] that came before [before].
  ///
  /// Backs the "+12% vs. last" line on the summary. Scoped to the same routine
  /// on purpose: comparing a leg day against the push day that happened to
  /// precede it would produce a number that looks meaningful and is not.
  Future<WorkoutSession?> previousSessionForRoutine(
    String routineId, {
    required DateTime before,
  }) {
    return (db.select(db.workoutSessions)
          ..where(
            (tbl) =>
                tbl.routineId.equals(routineId) &
                tbl.deletedAt.isNull() &
                tbl.finishedAt.isNotNull() &
                tbl.startedAt.isSmallerThanValue(before),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// A finished session by id, for the summary and history detail.
  Future<WorkoutSession?> findSession(String sessionId) {
    return (db.select(db.workoutSessions)
          ..where((tbl) => tbl.id.equals(sessionId) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// A session's exercises with their sets, as a one-shot read.
  ///
  /// The streaming variant is for the live workout; a finished session does not
  /// change, and awaiting a stream inside a widget build is a deadlock waiting
  /// to happen.
  Future<List<WorkoutExerciseDetail>> sessionExercises(String sessionId) async {
    final rows =
        await (db.select(db.workoutExercises).join([
                innerJoin(
                  db.exercises,
                  db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
                ),
                leftOuterJoin(
                  db.workoutSets,
                  db.workoutSets.workoutExerciseId.equalsExp(
                        db.workoutExercises.id,
                      ) &
                      db.workoutSets.deletedAt.isNull(),
                ),
              ])
              ..where(
                db.workoutExercises.sessionId.equals(sessionId) &
                    db.workoutExercises.deletedAt.isNull(),
              )
              ..orderBy([
                OrderingTerm.asc(db.workoutExercises.position),
                OrderingTerm.asc(db.workoutSets.setNumber),
              ]))
            .get();

    return _groupSessionExercises(rows);
  }

  // --- Exercises within a session -------------------------------------------

  /// Watches a session's exercises, each with its library row and its sets.
  ///
  /// One joined query, regrouped in memory, rather than a query per exercise.
  /// That is not an optimization — it is what makes the stream correct. Drift
  /// invalidates a watched query only when a table the query *mentions*
  /// changes, so fetching sets separately would leave this stream silent when
  /// a set is checked off, which is the one update the workout screen exists
  /// to render.
  Stream<List<WorkoutExerciseDetail>> watchSessionExercises(String sessionId) {
    final query =
        db.select(db.workoutExercises).join([
            innerJoin(
              db.exercises,
              db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
            ),
            leftOuterJoin(
              db.workoutSets,
              db.workoutSets.workoutExerciseId.equalsExp(
                    db.workoutExercises.id,
                  ) &
                  db.workoutSets.deletedAt.isNull(),
            ),
          ])
          ..where(
            db.workoutExercises.sessionId.equals(sessionId) &
                db.workoutExercises.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(db.workoutExercises.position),
            OrderingTerm.asc(db.workoutSets.setNumber),
          ]);

    return query.watch().map(_groupSessionExercises);
  }

  /// Collapses the row-per-set join back into one entry per exercise.
  ///
  /// Order comes from the query, and insertion order into [order] preserves it.
  List<WorkoutExerciseDetail> _groupSessionExercises(List<TypedResult> rows) {
    final order = <String>[];
    final entries = <String, WorkoutExercise>{};
    final libraryRows = <String, Exercise>{};
    final sets = <String, List<WorkoutSet>>{};

    for (final row in rows) {
      final entry = row.readTable(db.workoutExercises);
      if (!entries.containsKey(entry.id)) {
        order.add(entry.id);
        entries[entry.id] = entry;
        libraryRows[entry.id] = row.readTable(db.exercises);
        sets[entry.id] = [];
      }

      // Null for an exercise with no sets yet — that is what the outer join is
      // for, and the exercise still has to appear.
      final set = row.readTableOrNull(db.workoutSets);
      if (set != null) sets[entry.id]!.add(set);
    }

    return [
      for (final id in order)
        WorkoutExerciseDetail(
          entry: entries[id]!,
          exercise: libraryRows[id]!,
          sets: sets[id]!,
        ),
    ];
  }

  /// Adds an exercise to a session in progress, with [targetSets] empty sets
  /// ready to fill in.
  Future<WorkoutExercise> addExercise({
    required String sessionId,
    required String exerciseId,
    int targetSets = 3,
    int restSeconds = 90,
    int? supersetGroup,
  }) {
    return db.transaction(() async {
      final position = await _nextExercisePosition(sessionId);
      final workoutExercise = await db
          .into(db.workoutExercises)
          .insertReturning(
            WorkoutExercisesCompanion.insert(
              sessionId: sessionId,
              exerciseId: exerciseId,
              position: position,
              restSeconds: Value(restSeconds),
              supersetGroup: Value(supersetGroup),
            ),
          );

      final previous = await previousPerformance(exerciseId);
      for (var number = 1; number <= targetSets; number++) {
        final suggestion = previous?.suggestionFor(number);
        await db
            .into(db.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                workoutExerciseId: workoutExercise.id,
                setNumber: number,
                weight: Value(suggestion?.weight),
                reps: Value(suggestion?.reps),
              ),
            );
      }

      await touch(db.workoutSessions, sessionId);
      return workoutExercise;
    });
  }

  Future<void> removeExercise(String workoutExerciseId) {
    return db.transaction(() async {
      final sets = await _setsOf(workoutExerciseId);
      for (final set in sets) {
        await softDelete(db.workoutSets, set.id);
      }
      await softDelete(db.workoutExercises, workoutExerciseId);
    });
  }

  // --- Sets -----------------------------------------------------------------

  /// Appends a set to an exercise.
  Future<WorkoutSet> addSet(
    String workoutExerciseId, {
    SetType type = SetType.normal,
    double? weight,
    int? reps,
  }) {
    return db.transaction(() async {
      final setNumber = await _nextSetNumber(workoutExerciseId);
      return db
          .into(db.workoutSets)
          .insertReturning(
            WorkoutSetsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: setNumber,
              type: Value(type),
              weight: Value(weight),
              reps: Value(reps),
            ),
          );
    });
  }

  /// Edits a set without changing whether it is completed.
  Future<void> updateSet(
    String setId, {
    double? weight,
    int? reps,
    int? rir,
    SetType? type,
  }) {
    return db.transaction(() async {
      await (db.update(
        db.workoutSets,
      )..where((tbl) => tbl.id.equals(setId))).write(
        WorkoutSetsCompanion(
          weight: Value.absentIfNull(weight),
          reps: Value.absentIfNull(reps),
          rir: Value.absentIfNull(rir),
          type: Value.absentIfNull(type),
        ),
      );
      await touch(db.workoutSets, setId);
    });
  }

  /// Checks a set off.
  ///
  /// This is the write the whole architecture exists to make instant: it
  /// touches local storage only, and the UI can render the result before the
  /// future even resolves.
  Future<void> completeSet(
    String setId, {
    double? weight,
    int? reps,
    int? rir,
  }) {
    return db.transaction(() async {
      await (db.update(
        db.workoutSets,
      )..where((tbl) => tbl.id.equals(setId))).write(
        WorkoutSetsCompanion(
          weight: Value.absentIfNull(weight),
          reps: Value.absentIfNull(reps),
          rir: Value.absentIfNull(rir),
          completed: const Value(true),
          completedAt: Value(nowUtc()),
        ),
      );
      await touch(db.workoutSets, setId);
    });
  }

  /// Un-checks a set, for the mis-tap.
  Future<void> uncompleteSet(String setId) {
    return db.transaction(() async {
      await (db.update(
        db.workoutSets,
      )..where((tbl) => tbl.id.equals(setId))).write(
        const WorkoutSetsCompanion(
          completed: Value(false),
          completedAt: Value(null),
        ),
      );
      await touch(db.workoutSets, setId);
    });
  }

  Future<void> removeSet(String setId) => softDelete(db.workoutSets, setId);

  // --- Export ---------------------------------------------------------------

  /// Every completed set in every finished session, oldest first (spec §12).
  ///
  /// Two filters worth stating, because an export that quietly disagrees with
  /// the app's own totals is worse than no export:
  ///
  /// - **Finished sessions only.** The workout happening right now is not yet
  ///   a record of anything, and exporting it mid-set would write a row the
  ///   user is still editing.
  /// - **Completed sets only.** A planned set nobody checked off did not
  ///   happen. Leaving it in would make any `weight × reps` column a
  ///   spreadsheet sums disagree with the volume this app shows.
  ///
  /// Warm-ups *are* included, unlike in volume: they were performed, and the
  /// row says so in its type column, which leaves the filtering to whoever
  /// opens the file.
  Future<List<ExportedSet>> exportCompletedSets() async {
    final rows =
        await (db.select(db.workoutSessions).join([
                innerJoin(
                  db.workoutExercises,
                  db.workoutExercises.sessionId.equalsExp(
                        db.workoutSessions.id,
                      ) &
                      db.workoutExercises.deletedAt.isNull(),
                ),
                innerJoin(
                  db.workoutSets,
                  db.workoutSets.workoutExerciseId.equalsExp(
                        db.workoutExercises.id,
                      ) &
                      db.workoutSets.deletedAt.isNull() &
                      db.workoutSets.completed.equals(true),
                ),
                innerJoin(
                  db.exercises,
                  db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
                ),
                // Outer, and without a tombstone filter: a session started from
                // a routine the user has since deleted still has to name it.
                leftOuterJoin(
                  db.routines,
                  db.routines.id.equalsExp(db.workoutSessions.routineId),
                ),
              ])
              ..where(
                db.workoutSessions.deletedAt.isNull() &
                    db.workoutSessions.finishedAt.isNotNull(),
              )
              ..orderBy([
                OrderingTerm.asc(db.workoutSessions.startedAt),
                OrderingTerm.asc(db.workoutExercises.position),
                OrderingTerm.asc(db.workoutSets.setNumber),
              ]))
            .get();

    return [
      for (final row in rows)
        ExportedSet(
          session: row.readTable(db.workoutSessions),
          exercise: row.readTable(db.exercises),
          set: row.readTable(db.workoutSets),
          routineName: row.readTableOrNull(db.routines)?.name,
        ),
    ];
  }

  // --- Previous performance -------------------------------------------------

  /// What the user did the last time they trained [exerciseId].
  ///
  /// Looks only at finished sessions: an abandoned or in-progress workout is
  /// not a performance to compare against. [excludeSessionId] keeps the current
  /// session out when this is called mid-workout.
  Future<PreviousPerformance?> previousPerformance(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    var filter =
        db.workoutExercises.exerciseId.equals(exerciseId) &
        db.workoutExercises.deletedAt.isNull() &
        db.workoutSets.completed.equals(true) &
        db.workoutSets.deletedAt.isNull() &
        db.workoutSessions.finishedAt.isNotNull() &
        db.workoutSessions.deletedAt.isNull();

    if (excludeSessionId != null) {
      filter = filter & db.workoutSessions.id.equals(excludeSessionId).not();
    }

    // Find the most recent qualifying session first, then read its sets. Two
    // bounded queries rather than one that pulls the exercise's whole history
    // and throws most of it away.
    final sessionRow =
        await (db.select(db.workoutSessions).join([
                innerJoin(
                  db.workoutExercises,
                  db.workoutExercises.sessionId.equalsExp(
                    db.workoutSessions.id,
                  ),
                ),
                innerJoin(
                  db.workoutSets,
                  db.workoutSets.workoutExerciseId.equalsExp(
                    db.workoutExercises.id,
                  ),
                ),
              ])
              ..where(filter)
              ..orderBy([OrderingTerm.desc(db.workoutSessions.startedAt)])
              ..limit(1))
            .getSingleOrNull();

    if (sessionRow == null) return null;
    final session = sessionRow.readTable(db.workoutSessions);

    final setRows =
        await (db.select(db.workoutSets).join([
                innerJoin(
                  db.workoutExercises,
                  db.workoutExercises.id.equalsExp(
                    db.workoutSets.workoutExerciseId,
                  ),
                ),
              ])
              ..where(
                db.workoutExercises.sessionId.equals(session.id) &
                    db.workoutExercises.exerciseId.equals(exerciseId) &
                    db.workoutExercises.deletedAt.isNull() &
                    db.workoutSets.completed.equals(true) &
                    db.workoutSets.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm.asc(db.workoutSets.setNumber)]))
            .get();

    return PreviousPerformance(
      session: session,
      sets: setRows.map((row) => row.readTable(db.workoutSets)).toList(),
    );
  }

  // --- Internals ------------------------------------------------------------

  Future<List<WorkoutSet>> _setsOf(String workoutExerciseId) {
    return (db.select(db.workoutSets)
          ..where(
            (tbl) =>
                tbl.workoutExerciseId.equals(workoutExerciseId) &
                tbl.deletedAt.isNull(),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.setNumber)]))
        .get();
  }

  Future<void> _assertNoActiveSession() async {
    final active = await activeSession();
    if (active != null) {
      throw StateError(
        'A workout is already in progress (${active.id}). '
        'Finish or discard it before starting another.',
      );
    }
  }

  Future<int> _nextExercisePosition(String sessionId) async {
    final max = db.workoutExercises.position.max();
    final query = db.selectOnly(db.workoutExercises)
      ..addColumns([max])
      ..where(
        db.workoutExercises.sessionId.equals(sessionId) &
            db.workoutExercises.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<int> _nextSetNumber(String workoutExerciseId) async {
    final max = db.workoutSets.setNumber.max();
    final query = db.selectOnly(db.workoutSets)
      ..addColumns([max])
      ..where(
        db.workoutSets.workoutExerciseId.equals(workoutExerciseId) &
            db.workoutSets.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return (row.read(max) ?? 0) + 1;
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(appDatabaseProvider)),
);
