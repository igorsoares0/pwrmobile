# PWR

Offline-first gym workout tracker. Flutter mobile client.

The product spec lives in [`docs/PWR-Spec-Driven-Development.md`](docs/PWR-Spec-Driven-Development.md).
The clickable prototype the visual design follows is `docs/PWR Treino - App.dc (1).html`.

## Status

**Phase 1 — Offline Core is complete**, and the MVP flow the spec calls its
success criterion (§23) runs end to end with no network: open → pick a routine
→ start → log weight and reps → rest timer → finish → summary → history.

Remaining from the MVP checklist (§21): **CSV export**. After that, Phase 2
(Firebase Auth) and Phase 3 (FastAPI backend + sync).

## Running

```sh
flutter pub get
flutter run
```

A fresh install boots into onboarding; afterwards, into the home screen. The
design system gallery lives at `/design` — a reference screen rendering every
token and component, not a product screen.

Regenerate localisations after editing `lib/l10n/*.arb`:

```sh
flutter gen-l10n
```

```sh
flutter analyze
flutter test
```

## Structure

```text
lib/
├── app/            Application shell
│   ├── app.dart      Root widget
│   ├── router.dart   GoRouter configuration
│   └── theme/        Design system tokens
├── core/           Cross-cutting infrastructure
│   ├── auth/         Firebase Auth (phase 2)
│   ├── catalog/      Bundled exercise catalogue + locale resolution
│   ├── database/     Drift / SQLite
│   ├── network/      HTTP client (phase 3)
│   ├── storage/      Key-value preferences
│   └── sync/         Sync queue and cursor (phase 3)
├── features/       One folder per feature, each self-contained
│   ├── onboarding/  home/  routines/  exercises/  workout/
│   ├── history/  progress/  body/  sharing/
│   └── subscription/  profile/
├── l10n/           ARB sources + generated AppLocalizations
└── shared/         Reusable across features
    ├── widgets/      Design system components
    ├── components/   Composite widgets built from those
    ├── utils/        Formatters, extensions
    └── dev/          Design gallery (reference build only)
```

## Design system

Dark-first, minimal, technical. There is a single palette; no light theme.

### Tokens

| File | Contains |
| --- | --- |
| `app/theme/pwr_colors.dart` | `PwrColors` — surfaces, borders, text, accent ramp, set-type accents |
| `app/theme/pwr_typography.dart` | `PwrTypography` — the full type scale for both families |
| `app/theme/pwr_spacing.dart` | `PwrSpacing`, `PwrRadius`, `PwrDuration` |
| `app/theme/pwr_theme.dart` | `PwrTheme.dark` — the tokens wired into a Material `ThemeData` |

Import the barrel:

```dart
import 'package:pwrmobile/app/theme/theme.dart';
```

### Typography

Two families with a strict division of labour:

- **Poppins** — anything read as language: headings, labels, descriptions, buttons.
- **Azeret Mono** — anything read as a number or technical marker: weights, reps,
  timers, volume, section overlines, chips.

Monospaced numbers mean a set row does not reflow when a weight goes from `9`
to `10`, which matters because it is the screen the user looks at most.

Both fonts are bundled as assets under `assets/fonts/` rather than fetched at
runtime — the app has to work with no network. Azeret Mono ships upstream only
as a variable font, so the four weights here were instanced from it with
`fontTools`. Both are SIL Open Font Licensed; the license texts sit next to the
font files.

### Components

`shared/widgets/`, exported via `shared/widgets/widgets.dart`:

| Component | Use |
| --- | --- |
| `PwrButton` | Pill button — `primary`, `secondary`, `ghost`; `large` or `compact` |
| `PwrCard` | Surface container — default, `.accent`, `.dashed` |
| `PwrListRow` | Title + mono subtitle + chevron; `.placeholder` for locked content |
| `PwrTag` | Pill chip — `accent`, `neutral`, `outlined` |
| `PwrOverline` | Wide-tracked mono section label, uppercased automatically |
| `PwrStat` / `PwrStatRow` | Metric value over a mono caption |
| `PwrProgressBar` | Workout completion bar |

Run the app and look at `/design` to see all of them rendered at once.

## Data layer

Drift over SQLite, in `lib/core/database/`. This is the source of truth for the
app — nothing in the workout flow reads from or waits on the network.

```text
core/database/
├── app_database.dart       @DriftDatabase, schema version, migrations
├── app_database.g.dart     generated — commit it, do not edit it
├── database_provider.dart  Riverpod handle
├── enums.dart              MuscleGroup, Equipment, SetType, sync enums
├── repositories/           the only way features touch the database
│   ├── repository.dart       shared touch / softDelete
│   ├── models.dart           joined read models
│   ├── exercise_repository.dart
│   ├── routine_repository.dart
│   └── workout_repository.dart
└── tables/
    ├── synced_table.dart   the sync-metadata mixin every entity carries
    ├── exercises.dart
    ├── routines.dart  routine_exercises.dart
    ├── workout_sessions.dart  workout_exercises.dart  workout_sets.dart
    └── sync_operations.dart
```

Regenerate after changing any table:

```sh
dart run build_runner build
```

### Schema

```text
Exercise ──┬─< RoutineExercise >── Routine
           │                          │
           └─< WorkoutExercise >── WorkoutSession
                     │
                     └─< WorkoutSet
```

`SyncOperations` stands apart — it is the local outbound queue, not a
synchronized entity.

### Invariants

Every entity table mixes in `SyncedTable`, which enforces three rules that come
straight from the offline-first design:

1. **The device mints the id.** UUID v7, generated client-side. Rows are created
   offline and must be referenceable before the backend has ever seen them.
   Ordering by id is millisecond-granular only — sort on timestamps when real
   chronology matters.
2. **Deletes are soft.** `deletedAt` is set instead of removing the row. A hard
   delete leaves the backend no tombstone, and other devices would resurrect the
   row on their next pull. Every user-facing query must filter `deletedAt IS
   NULL`.
3. **Every mutation bumps `version`.** Conflict resolution pairs it with
   `updatedAt`: highest version wins, `updatedAt` breaks ties.

Further choices worth knowing:

- **Timestamps are ISO-8601 UTC text**, not Unix seconds (`build.yaml`). They go
  into sync payloads verbatim, and second-granularity ties far too often when a
  user checks off several sets in a row.
- **Enums are stored by name**, not index, so reordering an enum never corrupts
  existing rows.
- **Weight is always kilograms.** Unit preference is a display concern; one
  canonical unit keeps volume sums and PRs comparable for a user who switches.
- **Foreign keys are enforced** via `PRAGMA foreign_keys = ON` in `beforeOpen`.
  SQLite leaves them off by default, per connection.
- **No denormalized name snapshots** in history. Soft deletes keep every join
  resolving, so a session still renders after its routine is deleted. The
  tradeoff: renaming an exercise updates it retroactively across history, which
  is the desirable reading — it is the same movement.

### Repositories

`lib/core/database/repositories/`. **Features talk to these, never to
`AppDatabase` directly** — the three invariants above are enforced here so no
feature has to remember them. Getting one wrong in a feature would not fail
loudly; it would quietly corrupt what the backend sees in Phase 3.

| Repository | Covers |
| --- | --- |
| `ExerciseRepository` | Library CRUD, region filter, search, per-region counts |
| `RoutineRepository` | Routines, their exercise slots, drag reordering |
| `WorkoutRepository` | Sessions, sets, volume, history, previous performance |

The shared base (`repository.dart`) provides `touch` and `softDelete`. Both use
`customUpdate` rather than a typed companion: `version = version + 1` has to be
evaluated by SQLite so concurrent writers cannot read the same value, and the
timestamp goes through a typed `Variable` so drift applies its own encoding
instead of this code hard-coding a format the build options control.
`softDelete` is guarded by `deleted_at IS NULL`, so deleting twice does not
inflate the version and queue a redundant sync operation.

Notable behaviours:

- **Previous performance** (spec §11) reads the last *finished* session for an
  exercise. `startFromRoutine` uses it to pre-fill each planned set with what
  the user lifted in that slot last time — the reason the app beats a notebook
  from the second session onwards.
- **One workout at a time.** `startFromRoutine`/`startEmpty` throw a
  `StateError` if a session is already open. Resuming or discarding is a UI
  decision, not a silent one for this layer.
- **Unchecked sets are kept** when a session finishes. Every read filters on
  `completed`, and the gap between planned and performed is real information.
- **Volume excludes warm-ups and unchecked sets**, in both the Dart getter and
  the SQL aggregate.
- **The Free-plan routine cap is not enforced here.** `countRoutines()` reports
  the number; the limit depends on the PRO entitlement, which does not exist
  until Phase 4.

`watchSessionExercises` is one joined query regrouped in memory rather than a
query per exercise. That is correctness, not optimization: drift invalidates a
watched query only when a table the query *mentions* changes, so fetching sets
separately leaves the stream silent when a set is checked off — the one update
the workout screen exists to render. There is a regression test for it.

## Screens

| Route | Screen | Notes |
| --- | --- | --- |
| `/welcome` | Onboarding | First launch only; the flag lives in `app_settings` |
| `/` | Home | Weekly stats, routines, resume banner |
| `/history` | History | Finished sessions grouped by month |
| `/body`, `/profile` | Placeholders | Phase 5 and Phase 2; they say so |
| `/library`, `/library/pick` | Exercise library | Browse, or pick for a routine/workout |
| `/routines/:id` | Routine builder | Writes through on every keystroke |
| `/workout/:id` | Workout | The set row — the product's main screen |
| `/summary/:id` | Workout summary | Totals, comparison, share card |

The first four sit inside a `StatefulShellRoute` with the bottom navigation, so
each tab keeps its own stack. The rest are pushed over the shell: a workout
should not compete with a tab bar for the user's thumb.

## Localisation

UI strings live in `lib/l10n/app_en.arb` and `app_pt.arb`, generated into
`AppLocalizations` by `flutter gen-l10n`. English is the template and the
fallback for any unsupported locale.

Two separate systems, deliberately:

| What | Where | Why |
| --- | --- | --- |
| UI strings | ARB → `AppLocalizations` | Standard Flutter tooling, plural/placeholder support |
| Exercise names | `assets/catalog/exercises.json` | Catalogue data, not interface copy — replaced wholesale by an app update |

Flutter resolves the locale from the platform, narrowed to `supportedLocales`.
Widgets read it from `Localizations.localeOf(context)`; exercise names resolve
through the catalogue against the same locale.

## Home screen

`lib/features/home/`. The landing screen: what you did this week, and the
routine you are about to run. Everything on it is one tap from starting a
workout.

- **Weekly stats** — workouts, volume and completed sets for the current week.
  Weeks start Monday (ISO-8601), and sessions count by when they *started*, so
  a workout begun at 23:40 Sunday belongs to that Sunday.
- **Resume banner** — an unfinished session means the user walked away
  mid-workout. Surfacing it on home is what makes the offline crash-recovery
  visible instead of buried behind navigation.
- **Routine list** — the first routine gets the accent card and the play
  button; it is the one most likely to be run, and it should be reachable
  without reading the list.
- **Empty state** — a fresh install has no routines, so it explains what a
  routine *is* rather than showing a blank list.
- **Loading state** — placeholder blocks, not a spinner, so nothing resizes
  under the user's thumb when the data lands.

The Free routine cap lives in `features/subscription/entitlement.dart`, not in
the repository: the limit depends on the PRO entitlement, which arrives in
Phase 4. Everyone is `Entitlement.free` until then — showing PRO features as
unlocked before purchasing exists would be a lie the UI has to un-tell.

### Not derivable yet

The prototype's home shows a gym name and a "new records" stat. Neither has
data behind it — there is no profile until Phase 2 auth, and no
`PersonalRecord` table until Phase 5. The gym chip is omitted and the third
stat shows completed sets instead. Filling them with placeholder values would
have made the screen look finished while being false.

## Exercise library

`lib/features/exercises/`. Browse, search and extend the catalogue.

- **Search matches every bundled locale**, diacritic-insensitive. With the app
  in Portuguese, typing `bench press` still finds "Supino reto com barra" — the
  `name` column holds English, so matching slugs come from the catalogue and
  the SQL `LIKE` is kept only for user-created rows.
- **Sections by region** in fixed order, so the list does not reshuffle while
  the user types. Chips filter; tapping the active chip clears it.
- **Creating a custom exercise is a Free feature** (spec §12). The prototype
  shows it behind a PRO lock; the spec wins. A library where the machine your
  gym has cannot be added does not replace a notebook.
- **A search with no results flows into creating it**, with the term prefilled.
  That is the moment the user knows exactly what they want to add.
- The row subtitle shows **equipment**, not the prototype's `1RM 104KG`: 1RM is
  PRO (§13) and needs the Phase 5 `PersonalRecord` table.

`ExerciseLibraryScreen` takes an optional `onSelect`, so the routine builder can
reuse it as a picker rather than growing a near-duplicate screen.

## Testing widget screens

Every screen renders from drift streams, and drift schedules a `Timer.run` to
expire a query's cache when its last listener goes away. Two consequences, both
of which cost real time to diagnose:

**Never wait unbounded.** `pumpAndSettle`, `scrollUntilVisible` (it calls
`pumpAndSettle` internally), `await repo.watchX().first`, and `await db.close()`
inside a test body all hang until the 10-minute timeout. Use bounded pumps and
assert through the UI.

**Flush inside the test body.** The binding checks for pending timers *before*
`package:test` teardowns run, so `addTearDown` is too late. Both test files wrap
`testWidgets` to unmount and pump before finishing.

To reach an off-screen row, filter the list rather than scrolling to it —
`scrollUntilVisible` also fails with "Too many elements" on a screen with more
than one `Scrollable`.

**Real async needs `tester.runAsync`.** Three things in this app are genuinely
asynchronous and never complete under a widget test's fake clock:

| What | Why |
| --- | --- |
| `startFromRoutine` and other transactions | drift transactions do not resolve under the fake clock |
| `RepaintBoundary.toImage()` | rasterises through the engine |
| `await someStream.first` | waits on a timer only a pump can fire |

Wrap the first two in `runAsync`; replace the third with a one-shot read.

**Assert on types, not on copy.** The home empty state and onboarding share the
product's "three taps" promise, so `find.textContaining` matched the wrong
screen. `find.byType(OnboardingScreen)` cannot.

## Exercise catalogue

98 curated exercises ship as an asset at `assets/catalog/exercises.json`, with a
name per locale (currently `en` and `pt`). `lib/core/catalog/` loads it;
`ExerciseSeeder` materialises it into the database at startup.

Curated from [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
(MIT metadata). **No media is bundled** — see below.

### Why the catalogue is an asset, not rows

It is read-only reference data that an app update replaces wholesale. Storing
the per-locale names in the database instead would duplicate them into every
user's device and force a migration on every translation fix. The database
stores only the `slug`; everything language-dependent resolves at render time.

### Deterministic ids

Catalogue rows get their id from `catalogEntityId('exercise', slug)` — a UUID
**v5** hash of a fixed namespace plus the slug, so the same slug yields the same
id on every device and every install.

This is what stops the library from multiplying. With random ids, a user's phone
and tablet would each mint their own "Barbell Bench Press", and Phase 3 sync
would see two unrelated rows rather than one — with each device's history
pointing at its own copy, unmergeable after the fact.

`pwrIdNamespace` must never change once released. There is a test pinning a
known id literally so an accidental change fails loudly.

### Re-seeding

`ExerciseSeeder.seed` runs on every startup, not just on first install, so an
app update that adds exercises reaches existing users. It inserts only what is
missing (`INSERT OR IGNORE`) and never touches existing rows — a user may have
renamed a catalogue exercise, and re-seeding must not overwrite that. It also
avoids bumping `version` on untouched rows, which would queue a sync push for
the entire library on every app update.

### Names and search

- A **catalogue** exercise resolves its name per locale, falling back to the
  stored English name.
- A **user-created** exercise (`slug == null`) is shown exactly as typed — it is
  already in its author's language.
- **Search matches every bundled locale**, diacritic-insensitive. The `name`
  column holds English, so a SQL `LIKE` alone would never find "supino";
  matching slugs are resolved through the catalogue first, with the `LIKE` kept
  for user-created rows.

### Media is deliberately absent

Exercise demo GIFs are not in the MVP and not in this repo. The spec's MVP list
(§21) does not include them, and the upstream media is © Gym Visual, requiring a
separate commercial licence.

`source.mediaId` is preserved in the catalogue asset so media can be attached
later — licensing Gym Visual, buying the ExerciseDB dataset, or using the
public-domain [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
stills — without re-curating, migrating the schema, or touching user history.

### Migrations

**Bump `schemaVersion` and add an `onUpgrade` step on every schema change.**
Skipping it because the app has not shipped is a trap that already bit once: a
development device is an install too, and it opens the old file with the new
code. Adding `app_settings` without a version bump made the app fail to boot
with `no such table`.

`test/core/database/migration_test.dart` runs against a **file** database
rather than the in-memory one, because the point is surviving a close and
reopen — and it asserts that upgrading keeps existing data, not just that the
new table appears.

### Not yet built

- `PersonalRecord` and `BodyMeasurement` — Phase 5 features, no schema cost to
  defer.
- The sync queue **logic**. The `sync_operations` table ships in schema version
  1 so that turning sync on in Phase 3 needs no migration of user data.
- Locales beyond `en` and `pt`. Adding one is a column of strings in the
  catalogue asset; nothing else changes.

## Dependency notes

Two upstream constraints shaped `pubspec.yaml` and are worth knowing before
adding packages:

- **No `riverpod_generator`.** It requires analyzer `^13` while `drift_dev` is
  on `^12`; the two cannot resolve together. Riverpod providers are declared by
  hand, which Riverpod 3 fully supports. Revisit when both land on the same
  analyzer major.
- **No `freezed`.** Same analyzer conflict with `drift_dev`, and largely
  redundant here — Drift generates immutable row classes with `copyWith` and
  value equality for every table. Non-database state uses Dart 3 sealed classes
  and records.
- `riverpod_lint` is configured in `analysis_options.yaml` under `plugins:`,
  not as a dev dependency — since 3.1 it is a native analysis server plugin.
- `build_runner` stays below 2.15.2, which needs a newer `meta` than the
  Flutter SDK pins.
