import 'package:flutter/material.dart';

import 'theme/theme.dart';

/// Shown when startup itself fails.
///
/// Without this the app paints nothing at all: `bootstrapPwr` runs before
/// `runApp`, so anything it throws leaves a black screen that is
/// indistinguishable from a hang. A migration that did not run should look
/// like a broken app, not a dead one.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PwrTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(PwrSpacing.screenH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('PWR', style: PwrTypography.wordmark),
                const SizedBox(height: PwrSpacing.lg),
                const Text(
                  // Deliberately not localised: the failure may well be that
                  // localisation never loaded.
                  'PWR could not start.',
                  style: PwrTypography.displaySmall,
                ),
                const SizedBox(height: PwrSpacing.sm),
                Text(
                  '$error',
                  style: PwrTypography.bodySmall.copyWith(
                    color: PwrColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
