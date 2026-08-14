import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/catalog/catalog_provider.dart';
import '../core/catalog/exercise_catalog.dart';
import '../core/database/database_provider.dart';
import '../core/database/exercise_seeder.dart';
import '../core/database/repositories/repositories.dart';

/// Prepares everything the first frame depends on, and returns the container
/// the app runs against.
///
/// Seeding happens here rather than inside the database's `beforeOpen` because
/// the catalogue is a Flutter asset: the database layer has no business
/// reaching into `rootBundle`. Doing it before `runApp` also means the library
/// is never briefly empty on screen — there is no loading state to design
/// around for 98 local inserts.
typedef PwrStartup = ({ProviderContainer container, bool showOnboarding});

Future<PwrStartup> bootstrapPwr() async {
  final catalog = await ExerciseCatalog.load();

  final container = ProviderContainer(
    overrides: [exerciseCatalogProvider.overrideWithValue(catalog)],
  );

  await ExerciseSeeder(container.read(appDatabaseProvider)).seed(catalog);

  final seen = await container
      .read(settingsRepositoryProvider)
      .getFlag(SettingsRepository.onboardingSeen);

  return (container: container, showOnboarding: !seen);
}
