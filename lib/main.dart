import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/startup_failure_app.dart';
import 'app/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: PwrColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Logging a set is a portrait, one-handed action.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Startup runs before the first frame, so a failure here would otherwise
  // paint nothing at all. Surfacing it beats a black screen.
  try {
    final startup = await bootstrapPwr();

    runApp(
      UncontrolledProviderScope(
        container: startup.container,
        child: PwrApp(showOnboarding: startup.showOnboarding),
      ),
    );
  } catch (error, stack) {
    debugPrint('PWR failed to start: $error\n$stack');
    runApp(StartupFailureApp(error: error));
  }
}
