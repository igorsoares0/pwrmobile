import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'pwr_card.dart';

/// A screen that exists in the navigation but not yet in the product.
///
/// Says plainly what is missing and when it arrives, rather than showing an
/// empty list that looks broken or inventing content to fill the space.
class PwrNotBuilt extends StatelessWidget {
  const PwrNotBuilt({
    super.key,
    required this.title,
    required this.headline,
    required this.body,
  });

  final String title;
  final String headline;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PwrSpacing.screenH,
            PwrSpacing.screenTop,
            PwrSpacing.screenH,
            PwrSpacing.screenBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PwrTypography.titleMedium),
              const SizedBox(height: PwrSpacing.lg),
              PwrCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: PwrTypography.titleLarge),
                    const SizedBox(height: PwrSpacing.xs),
                    Text(
                      body,
                      style: PwrTypography.bodyLarge.copyWith(
                        color: PwrColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
