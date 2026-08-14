import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/database/repositories/repositories.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

/// The first screen a new install shows.
///
/// Its whole job is to set an expectation the product then keeps: three taps
/// to log a set, nothing else. It asks for nothing — no account, no
/// permissions, no email — because the app genuinely needs none of that to be
/// useful (spec §9).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            26,
            PwrSpacing.xxl,
            26,
            PwrSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PWR', style: PwrTypography.wordmark),
              const SizedBox(height: 44),

              Text.rich(
                TextSpan(
                  text: '${l10n.onboardingHeadline}\n',
                  children: [
                    TextSpan(
                      text: l10n.onboardingHeadlineAccent,
                      style: const TextStyle(color: PwrColors.accent),
                    ),
                  ],
                ),
                style: PwrTypography.displayLarge,
              ),
              const SizedBox(height: 18),
              Text(
                l10n.onboardingBody,
                style: PwrTypography.bodyLarge.copyWith(
                  color: PwrColors.textMuted,
                ),
              ),

              const SizedBox(height: PwrSpacing.xxl),
              _Step(
                number: '01',
                title: l10n.onboardingStep1,
                body: l10n.onboardingStep1Body,
              ),
              _Step(
                number: '02',
                title: l10n.onboardingStep2,
                body: l10n.onboardingStep2Body,
              ),
              _Step(
                number: '03',
                title: l10n.onboardingStep3,
                body: l10n.onboardingStep3Body,
                last: true,
              ),

              const Spacer(),
              Text(l10n.onboardingOffline, style: PwrTypography.caption),
              const SizedBox(height: PwrSpacing.sm),

              // No "I already have an account" here, unlike the prototype:
              // accounts arrive in phase 2, and the spec only asks for one
              // after the first workout anyway.
              PwrButton(
                label: l10n.onboardingStart,
                onPressed: () async {
                  await ref
                      .read(settingsRepositoryProvider)
                      .setFlag(SettingsRepository.onboardingSeen, value: true);
                  onStart?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });

  final String number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : PwrSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              number,
              style: PwrTypography.tag.copyWith(color: PwrColors.accent),
            ),
          ),
          const SizedBox(width: PwrSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PwrTypography.bodyMedium),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: PwrTypography.bodySmall.copyWith(
                    color: PwrColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
