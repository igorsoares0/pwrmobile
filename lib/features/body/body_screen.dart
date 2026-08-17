import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/theme.dart';
import '../../core/database/app_database.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import 'body_providers.dart';
import 'weigh_in_sheet.dart';

/// Body weight over time.
///
/// Free logs one number: what you weigh. Spec §13 reserves "medições corporais
/// avançadas" for PRO, and the perimeters the prototype grids out — chest,
/// waist, arm, thigh — plus progress photos are what "advanced" means here.
/// Body weight itself is not advanced, and it is the line underneath every
/// other number in the app: 12 000 kg of volume means one thing at 74 kg and
/// another at 82.
class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(measurementsProvider).value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PwrSpacing.screenH,
            PwrSpacing.screenTop,
            PwrSpacing.screenH,
            PwrSpacing.xxl,
          ),
          children: [
            Text(l10n.bodyTitle, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),

            // Null is "the stream has not delivered yet", empty is "this user
            // has never weighed in". They are different screens, and treating
            // the first as the second flashes an empty state at every visit.
            if (entries != null && entries.isEmpty)
              const _Empty()
            else
              const _TrendCard(),

            const SizedBox(height: PwrSpacing.md),
            PwrButton.secondary(
              label: l10n.bodyLogWeight,
              onPressed: () => WeighInSheet.show(context),
            ),

            // The user's own weigh-ins come before the locked section. Their
            // data outranks an upsell, and burying the history under four
            // padlocks would push it off the first screen entirely.
            if (entries != null && entries.isNotEmpty) ...[
              const SizedBox(height: PwrSpacing.xl),
              PwrOverline(l10n.bodyHistory, wide: true),
              const SizedBox(height: PwrSpacing.sm),
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: PwrSpacing.listGap),
                  child: _EntryRow(
                    entry: entries[i],
                    // Entries are newest first, so the one that came before is
                    // the next in the list.
                    previous: i + 1 < entries.length ? entries[i + 1] : null,
                  ),
                ),
            ],

            const SizedBox(height: PwrSpacing.xl),
            const _LockedMeasurements(),
          ],
        ),
      ),
    );
  }
}

/// Current weight, and how far it has moved.
class _TrendCard extends ConsumerWidget {
  const _TrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unit = ref.watch(weightUnitProvider);
    final trend = ref.watch(bodyTrendProvider).value;

    final weightKg = trend?.latest.weightKg;
    final delta = trend?.deltaKg;

    return PwrCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bodyCurrentWeight.toUpperCase(),
                  style: PwrTypography.metricCaption,
                ),
                const SizedBox(height: PwrSpacing.xs),
                Text.rich(
                  TextSpan(
                    // A placeholder dash rather than a zero while the stream
                    // resolves: `0 kg` is a claim, `—` is not.
                    text: weightKg == null
                        ? '—'
                        : formatSetLoad(weightKg, locale, unit: unit),
                    children: [
                      TextSpan(
                        text: ' ${unit.symbol.toUpperCase()}',
                        style: PwrTypography.metricLg.copyWith(
                          fontSize: 14,
                          color: PwrColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  style: PwrTypography.metricLg,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                delta == null
                    ? '—'
                    : '${delta < 0 ? '▼' : '▲'} '
                          '${delta < 0 ? '-' : '+'}'
                          '${formatSetLoad(delta.abs(), locale, unit: unit)}'
                          '${unit.symbol.toUpperCase()}',
                // Accent either way, never green-good / red-bad: a kilogram
                // down is progress on a cut and a setback on a bulk, and the
                // app has no idea which one the user is on.
                style: PwrTypography.tag.copyWith(color: PwrColors.accent),
              ),
              const SizedBox(height: PwrSpacing.xs),
              Text(
                (trend == null || delta == null
                        ? l10n.bodyNoBaseline
                        : l10n.bodyDeltaWeeks(trend.spanWeeks))
                    .toUpperCase(),
                style: PwrTypography.metricCaption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PwrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bodyEmptyHeadline, style: PwrTypography.titleLarge),
          const SizedBox(height: PwrSpacing.xs),
          Text(
            l10n.bodyEmptyBody,
            style: PwrTypography.bodyLarge.copyWith(
              color: PwrColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The perimeters, shown as locked rather than hidden.
///
/// Hiding them would make the screen look finished; a tappable row would
/// promise a paywall that does not exist until phase 4. So they are inert
/// placeholders that say what they are and what unlocks them.
class _LockedMeasurements extends StatelessWidget {
  const _LockedMeasurements();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.bodyChest,
      l10n.bodyWaist,
      l10n.bodyArm,
      l10n.bodyThigh,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: PwrOverline(l10n.bodyMeasurements, wide: true)),
            PwrTag(l10n.bodyLocked),
          ],
        ),
        const SizedBox(height: PwrSpacing.sm),
        for (final label in labels)
          Padding(
            padding: const EdgeInsets.only(bottom: PwrSpacing.listGap),
            child: PwrListRow.placeholder(
              title: label,
              subtitle: '—',
              trailing: const Icon(Icons.lock_outline, size: 16),
            ),
          ),
        const SizedBox(height: PwrSpacing.xs),
        Text(
          l10n.bodyMeasurementsLocked,
          style: PwrTypography.caption.copyWith(color: PwrColors.textFaint),
        ),
      ],
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, this.previous});

  final BodyMeasurement entry;

  /// The weigh-in before this one, for the per-entry change.
  final BodyMeasurement? previous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context);
    final unit = ref.watch(weightUnitProvider);
    final weightKg = entry.weightKg ?? 0;

    final before = previous?.weightKg;
    final delta = before == null ? null : weightKg - before;

    return PwrListRow(
      title: DateFormat.yMMMd(
        locale.toLanguageTag(),
      ).format(entry.measuredAt.toLocal()),
      subtitle: delta == null
          ? null
          : '${delta < 0 ? '▼ -' : '▲ +'}'
                '${formatSetLoad(delta.abs(), locale.toLanguageTag(), unit: unit)}',
      trailing: Text(
        '${formatSetLoad(weightKg, locale.toLanguageTag(), unit: unit)} '
        '${unit.symbol.toUpperCase()}',
        style: PwrTypography.metricXs,
      ),
      onTap: () => WeighInSheet.show(context, existing: entry),
    );
  }
}
