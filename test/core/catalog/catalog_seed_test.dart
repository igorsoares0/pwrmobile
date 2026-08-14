import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/catalog/exercise_catalog.dart';
import 'package:pwrmobile/core/catalog/exercise_display.dart';
import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/enums.dart';
import 'package:pwrmobile/core/database/exercise_seeder.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';
import 'package:pwrmobile/core/database/tables/synced_table.dart';

/// The real shipped catalogue, read straight off disk so a bad edit to the
/// asset fails here rather than in production.
ExerciseCatalog loadTestCatalog() => ExerciseCatalog.parse(
  File('assets/catalog/exercises.json').readAsStringSync(),
);

void main() {
  late AppDatabase db;
  late ExerciseCatalog catalog;
  late ExerciseSeeder seeder;
  late ExerciseRepository exercises;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    catalog = loadTestCatalog();
    seeder = ExerciseSeeder(db);
    exercises = ExerciseRepository(db, catalog);
  });

  tearDown(() async {
    await db.close();
  });

  group('catalogue asset', () {
    test('parses and carries the advertised locales', () {
      expect(catalog.exercises, isNotEmpty);
      expect(catalog.locales, containsAll(['en', 'pt']));
    });

    test('every entry has a name in every advertised locale', () {
      for (final exercise in catalog.exercises) {
        for (final locale in catalog.locales) {
          expect(
            exercise.names[locale],
            isNotNull,
            reason: '${exercise.slug} is missing a "$locale" name',
          );
          expect(exercise.names[locale], isNotEmpty);
        }
      }
    });

    test('slugs are unique', () {
      final slugs = catalog.exercises.map((e) => e.slug).toList();
      expect(slugs.toSet(), hasLength(slugs.length));
    });

    test('covers every muscle group the filters expose', () {
      final regions = catalog.exercises
          .map((e) => e.muscleGroup.region)
          .toSet();

      // An empty filter chip is a dead end for the user, so every coarse
      // bucket has to have something behind it.
      expect(regions, containsAll(MuscleGroupRegion.values));
    });
  });

  group('deterministic ids', () {
    test('the same slug always yields the same id', () {
      final first = catalogEntityId('exercise', 'barbell-bench-press');
      final second = catalogEntityId('exercise', 'barbell-bench-press');

      expect(first, second);
    });

    test('different slugs yield different ids', () {
      expect(
        catalogEntityId('exercise', 'barbell-bench-press'),
        isNot(catalogEntityId('exercise', 'dumbbell-bench-press')),
      );
    });

    test('ids are stable across app versions', () {
      // Pinned literally. If this fails, the namespace or the derivation
      // changed, and every existing install would orphan its workout history.
      expect(
        catalogEntityId('exercise', 'barbell-bench-press'),
        '3a69fc61-7395-5509-909c-7d3fcf124259',
      );
    });
  });

  group('seeding', () {
    test('inserts the whole catalogue on a fresh database', () async {
      final inserted = await seeder.seed(catalog);

      expect(inserted, catalog.exercises.length);
      final library = await exercises.watchLibrary().first;
      expect(library, hasLength(catalog.exercises.length));
      expect(library.every((e) => e.slug != null), isTrue);
      expect(library.every((e) => e.isCustom), isFalse);
    });

    test('re-seeding inserts nothing and duplicates nothing', () async {
      await seeder.seed(catalog);
      final inserted = await seeder.seed(catalog);

      expect(inserted, 0);
      final library = await exercises.watchLibrary().first;
      expect(library, hasLength(catalog.exercises.length));
    });

    test('re-seeding does not overwrite a user rename', () async {
      await seeder.seed(catalog);

      final id = catalogEntityId('exercise', 'barbell-bench-press');
      await exercises.update(id, name: 'Meu supino');

      await seeder.seed(catalog);

      final row = await exercises.findById(id);
      expect(row!.name, 'Meu supino');
    });

    test('re-seeding does not bump versions of untouched rows', () async {
      await seeder.seed(catalog);
      await seeder.seed(catalog);

      final id = catalogEntityId('exercise', 'barbell-bench-press');
      final row = await exercises.findById(id);

      // A version bump here would queue a sync push for the entire library on
      // every app update.
      expect(row!.version, 1);
    });

    test('only adds what is missing when the catalogue grows', () async {
      await seeder.seed(catalog);

      final grown = ExerciseCatalog.parse('''
      {
        "version": 2,
        "locales": ["en", "pt"],
        "exercises": [
          {"slug": "barbell-bench-press", "muscleGroup": "chest",
           "equipment": "barbell",
           "names": {"en": "Barbell Bench Press", "pt": "Supino reto com barra"}},
          {"slug": "brand-new-lift", "muscleGroup": "chest",
           "equipment": "barbell",
           "names": {"en": "Brand New Lift", "pt": "Novo exercício"}}
        ]
      }
      ''');

      final inserted = await seeder.seed(grown);
      expect(inserted, 1);
    });
  });

  group('localised names', () {
    setUp(() async {
      await seeder.seed(catalog);
    });

    test('a catalogue exercise resolves per locale', () async {
      final id = catalogEntityId('exercise', 'barbell-bench-press');
      final row = (await exercises.findById(id))!;

      expect(row.displayName(catalog, 'en'), 'Barbell Bench Press');
      expect(row.displayName(catalog, 'pt'), 'Supino reto com barra');
      expect(row.isFromCatalog, isTrue);
    });

    test('an unknown locale falls back to English', () async {
      final id = catalogEntityId('exercise', 'barbell-bench-press');
      final row = (await exercises.findById(id))!;

      expect(row.displayName(catalog, 'ja'), 'Barbell Bench Press');
    });

    test('a user-created exercise is shown exactly as typed', () async {
      final custom = await exercises.create(
        name: 'Rosca do meu treinador',
        muscleGroup: MuscleGroup.biceps,
        equipment: Equipment.dumbbell,
      );

      expect(custom.slug, isNull);
      expect(custom.isFromCatalog, isFalse);
      // Not translated in either direction — it is already in its author's
      // language, and rewriting it would be wrong.
      expect(custom.displayName(catalog, 'en'), 'Rosca do meu treinador');
      expect(custom.displayName(catalog, 'pt'), 'Rosca do meu treinador');
    });
  });

  group('localised search', () {
    setUp(() async {
      await seeder.seed(catalog);
    });

    test('finds a catalogue exercise by its Portuguese name', () async {
      final found = await exercises.watchLibrary(search: 'supino').first;

      expect(found, isNotEmpty);
      expect(
        found.map((e) => e.displayName(catalog, 'pt')),
        contains('Supino reto com barra'),
      );
    });

    test('finds the same exercise by its English name', () async {
      final found = await exercises.watchLibrary(search: 'bench press').first;

      expect(found.map((e) => e.slug), contains('barbell-bench-press'));
    });

    test('ignores diacritics', () async {
      final withAccent = await exercises.watchLibrary(search: 'tríceps').first;
      final without = await exercises.watchLibrary(search: 'triceps').first;

      expect(withAccent, isNotEmpty);
      expect(withAccent.map((e) => e.slug), without.map((e) => e.slug));
    });

    test('finds a user-created exercise by its literal name', () async {
      await exercises.create(
        name: 'Puxada do Zé',
        muscleGroup: MuscleGroup.back,
        equipment: Equipment.cable,
      );

      final found = await exercises.watchLibrary(search: 'Puxada do Zé').first;
      expect(found.map((e) => e.name), contains('Puxada do Zé'));
    });

    test('a search matching nothing returns nothing', () async {
      final found = await exercises.watchLibrary(search: 'zzzznope').first;
      expect(found, isEmpty);
    });
  });
}
