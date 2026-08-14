import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../database/enums.dart';

/// One exercise in the bundled catalogue.
class CatalogExercise {
  const CatalogExercise({
    required this.slug,
    required this.muscleGroup,
    required this.equipment,
    required this.names,
    this.sourceMediaId,
  });

  final String slug;
  final MuscleGroup muscleGroup;
  final Equipment equipment;

  /// Display name per ISO 639-1 language code.
  final Map<String, String> names;

  /// Upstream media reference, kept so demo images or GIFs can be attached
  /// later without re-curating the catalogue. Nothing reads it yet.
  final String? sourceMediaId;

  /// Canonical English name, used as the database fallback.
  String get canonicalName => names['en']!;

  /// The name for [languageCode], falling back to English.
  String nameFor(String languageCode) =>
      names[languageCode] ?? names[_fallbackLocale] ?? slug;

  static const String _fallbackLocale = 'en';

  factory CatalogExercise.fromJson(Map<String, dynamic> json) {
    return CatalogExercise(
      slug: json['slug'] as String,
      muscleGroup: MuscleGroup.values.byName(json['muscleGroup'] as String),
      equipment: Equipment.values.byName(json['equipment'] as String),
      names: (json['names'] as Map<String, dynamic>).cast<String, String>(),
      sourceMediaId:
          (json['source'] as Map<String, dynamic>?)?['mediaId'] as String?,
    );
  }
}

/// The bundled exercise catalogue.
///
/// Ships as an asset rather than rows in the database, for two reasons: it is
/// read-only reference data that a shipped app update replaces wholesale, and
/// the per-locale names would otherwise have to be duplicated into every user's
/// database and migrated on every translation fix.
///
/// The database stores only the slug. Everything language-dependent is resolved
/// through here at render time.
class ExerciseCatalog {
  const ExerciseCatalog._(this.exercises, this._bySlug, this.locales);

  final List<CatalogExercise> exercises;
  final Map<String, CatalogExercise> _bySlug;

  /// Language codes the catalogue carries names for.
  final List<String> locales;

  static const String assetPath = 'assets/catalog/exercises.json';

  static ExerciseCatalog? _cached;

  /// Loads and caches the catalogue.
  static Future<ExerciseCatalog> load() async {
    return _cached ??= parse(await rootBundle.loadString(assetPath));
  }

  /// Parses catalogue JSON. Exposed so tests can supply their own.
  static ExerciseCatalog parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final exercises = (json['exercises'] as List<dynamic>)
        .map((e) => CatalogExercise.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return ExerciseCatalog._(exercises, {
      for (final exercise in exercises) exercise.slug: exercise,
    }, (json['locales'] as List<dynamic>).cast<String>());
  }

  CatalogExercise? bySlug(String slug) => _bySlug[slug];

  /// Slugs whose name matches [query] in **any** bundled locale.
  ///
  /// Searching every locale rather than only the active one is deliberate: a
  /// bilingual user types whichever name comes to mind, and a Brazilian who
  /// knows a movement as "supino" should still find it with the app in
  /// English. The catalogue is small enough that scanning it costs nothing.
  Set<String> slugsMatching(String query) {
    final needle = _normalize(query);
    if (needle.isEmpty) return const {};

    return {
      for (final exercise in exercises)
        if (exercise.names.values.any(
          (name) => _normalize(name).contains(needle),
        ))
          exercise.slug,
    };
  }

  /// Lowercases and strips diacritics, so "tríceps" matches "triceps".
  static String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_foldedDiacritics[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  static const Map<int, String> _foldedDiacritics = {
    0xE1: 'a', 0xE0: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', // á à â ã ä
    0xE9: 'e', 0xE8: 'e', 0xEA: 'e', 0xEB: 'e', //             é è ê ë
    0xED: 'i', 0xEC: 'i', 0xEE: 'i', 0xEF: 'i', //             í ì î ï
    0xF3: 'o', 0xF2: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', //  ó ò ô õ ö
    0xFA: 'u', 0xF9: 'u', 0xFB: 'u', 0xFC: 'u', //             ú ù û ü
    0xE7: 'c', 0xF1: 'n', //                                   ç ñ
  };

  /// Replaces the cached instance. Test hook.
  static void debugSetCache(ExerciseCatalog? catalog) => _cached = catalog;
}
