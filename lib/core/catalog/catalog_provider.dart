import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exercise_catalog.dart';

/// The bundled exercise catalogue.
///
/// Deliberately has no default: reading it before startup has loaded the asset
/// is a wiring mistake, and failing loudly beats silently serving an empty
/// library. `bootstrapPwr` supplies the override.
final exerciseCatalogProvider = Provider<ExerciseCatalog>((ref) {
  throw StateError(
    'exerciseCatalogProvider was read before startup loaded the catalogue. '
    'Override it with the value returned by bootstrapPwr().',
  );
});
