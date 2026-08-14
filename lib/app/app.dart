import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/theme.dart';

/// Root widget.
///
/// Stateful only to own the router: it holds navigation state, so it is built
/// once per app instance rather than shared globally.
class PwrApp extends StatefulWidget {
  const PwrApp({super.key, this.showOnboarding = false});

  /// Whether this install has yet to see the welcome screen.
  final bool showOnboarding;

  @override
  State<PwrApp> createState() => _PwrAppState();
}

class _PwrAppState extends State<PwrApp> {
  late final GoRouter _router = createPwrRouter(
    showOnboarding: widget.showOnboarding,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PWR',
      debugShowCheckedModeBanner: false,
      theme: PwrTheme.dark,

      // Dark-first: there is no light palette to fall back to, so the system
      // setting is deliberately ignored.
      darkTheme: PwrTheme.dark,
      themeMode: ThemeMode.dark,

      routerConfig: _router,

      // Locale is resolved by Flutter from the platform, narrowed to what the
      // app actually has translations for. Exercise names follow the same
      // locale via the bundled catalogue.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Text scaling is honoured, but capped: the set row is a fixed grid and
      // stops being readable past this point.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
