import '../database/app_database.dart';
import 'exercise_catalog.dart';

/// Resolves what an exercise row is actually called on screen.
///
/// Kept out of [ExerciseCatalog] so the catalogue stays independent of the
/// database, and out of the repositories so those stay independent of locale.
extension ExerciseDisplayName on Exercise {
  /// The name to render, for the given ISO 639-1 language code.
  ///
  /// A user-created exercise is shown exactly as typed — it is already in the
  /// language its author chose, and translating it would be wrong. A catalogue
  /// exercise is looked up per locale, falling back to the stored English name
  /// if the catalogue no longer knows the slug (an exercise retired from a
  /// later app version, whose history must still render).
  String displayName(ExerciseCatalog catalog, String languageCode) {
    final slug = this.slug;
    if (slug == null) return name;
    return catalog.bySlug(slug)?.nameFor(languageCode) ?? name;
  }

  /// Whether this row came from the bundled catalogue.
  bool get isFromCatalog => slug != null;
}
