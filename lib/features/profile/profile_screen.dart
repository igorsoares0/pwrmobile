import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/settings/preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';
import '../sharing/share_service.dart';
import '../subscription/entitlement.dart';
import 'csv_export.dart';

/// Settings, and the account that does not exist yet.
///
/// The prototype puts a name, a gym and a subscription card at the top. None of
/// those have data behind them — auth is phase 2, RevenueCat is phase 4 — so
/// the header says what is true instead: this is a device, and the training on
/// it is local. Everything below the header is a preference that does something
/// the moment it is changed.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferences = ref.watch(preferencesProvider);

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
            Text(l10n.profileTitle, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),

            const _AccountCard(),
            const SizedBox(height: PwrSpacing.xl),

            PwrOverline(l10n.profileSectionTraining, wide: true),
            const SizedBox(height: PwrSpacing.sm),

            PwrListRow(
              title: l10n.profileWeightUnit,
              trailing: _Value(preferences.weightUnit.symbol.toUpperCase()),
              onTap: () => _WeightUnitSheet.show(context),
            ),
            const SizedBox(height: PwrSpacing.listGap),

            PwrListRow(
              title: l10n.profileDefaultRest,
              trailing: _Value(
                l10n
                    .slotRestSeconds(preferences.defaultRestSeconds)
                    .toUpperCase(),
              ),
              onTap: () => _DefaultRestSheet.show(context),
            ),
            const SizedBox(height: PwrSpacing.listGap),

            PwrListRow(
              title: l10n.profileTimerSound,
              // The switch is the whole row's control, so the row itself does
              // not also navigate — a chevron here would promise a screen that
              // is not there.
              trailing: Switch(
                value: preferences.timerSound,
                onChanged: (value) => ref
                    .read(preferencesProvider.notifier)
                    .setTimerSound(enabled: value),
              ),
            ),

            const SizedBox(height: PwrSpacing.xl),
            PwrOverline(l10n.profileSectionData, wide: true),
            const SizedBox(height: PwrSpacing.sm),

            const _ExportRow(),

            const SizedBox(height: PwrSpacing.lg),
            Text(
              l10n.profileAccountNote,
              style: PwrTypography.caption.copyWith(color: PwrColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Who this install belongs to, as far as the app can honestly say.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entitlement = ref.watch(entitlementProvider);

    return PwrCard(
      child: Row(
        children: [
          // No initial to put in the circle without a name, so the placeholder
          // is a glyph rather than a letter picked at random.
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: PwrColors.accentStrong,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: PwrColors.onAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: PwrSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileAccountTitle,
                  style: PwrTypography.titleSmall,
                ),
                const SizedBox(height: 7),
                Text(
                  entitlement.isPro
                      ? 'PRO'
                      : l10n.profileAccountSubtitle.toUpperCase(),
                  style: PwrTypography.tag,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The trailing value on a settings row: the current choice, then the chevron.
class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: PwrTypography.tag),
        const SizedBox(width: PwrSpacing.xs),
        const Icon(Icons.arrow_forward, size: 16),
      ],
    );
  }
}

class _WeightUnitSheet extends ConsumerWidget {
  const _WeightUnitSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _WeightUnitSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(weightUnitProvider);

    return _Sheet(
      title: l10n.profileWeightUnitSheet,
      children: [
        Wrap(
          spacing: PwrSpacing.xs,
          runSpacing: PwrSpacing.xs,
          children: [
            for (final unit in WeightUnit.values)
              PwrTag(
                unit.symbol.toUpperCase(),
                tone: unit == current ? PwrTagTone.accent : PwrTagTone.neutral,
                onTap: () async {
                  await ref
                      .read(preferencesProvider.notifier)
                      .setWeightUnit(unit);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DefaultRestSheet extends ConsumerWidget {
  const _DefaultRestSheet();

  /// The same steps the slot editor offers, for the same reason: these are the
  /// rests people actually use, and a free-running stepper takes twelve taps to
  /// get from 60 to 180.
  static const _steps = [30, 45, 60, 90, 120, 150, 180, 240];

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _DefaultRestSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(
      preferencesProvider.select((p) => p.defaultRestSeconds),
    );

    return _Sheet(
      title: l10n.profileDefaultRestSheet,
      children: [
        Wrap(
          spacing: PwrSpacing.xs,
          runSpacing: PwrSpacing.xs,
          children: [
            for (final seconds in _steps)
              PwrTag(
                l10n.slotRestSeconds(seconds).toUpperCase(),
                tone: seconds == current
                    ? PwrTagTone.accent
                    : PwrTagTone.neutral,
                onTap: () async {
                  await ref
                      .read(preferencesProvider.notifier)
                      .setDefaultRestSeconds(seconds);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
        const SizedBox(height: PwrSpacing.md),
        Text(
          l10n.profileDefaultRestNote,
          style: PwrTypography.caption.copyWith(color: PwrColors.textFaint),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          PwrSpacing.screenH,
          PwrSpacing.xs,
          PwrSpacing.screenH,
          PwrSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: PwrTypography.titleMedium),
            const SizedBox(height: PwrSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Builds the CSV and hands it to the share sheet (spec §12).
class _ExportRow extends ConsumerStatefulWidget {
  const _ExportRow();

  @override
  ConsumerState<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends ConsumerState<_ExportRow> {
  bool _busy = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final file = await ref.read(csvExportProvider(language)).build();

      // An empty file is a worse answer than a sentence. Someone who has not
      // finished a workout yet would otherwise share a header row and be left
      // wondering what went wrong.
      if (file.setCount == 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profileExportEmpty)),
        );
        return;
      }

      await ref
          .read(shareServiceProvider)
          .shareText(
            file.contents,
            fileName: 'pwr-export-${_stamp(DateTime.now())}.csv',
            mimeType: 'text/csv',
            subject: l10n.profileExportSubject(file.setCount),
          );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileExportFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _stamp(DateTime now) {
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PwrListRow(
      title: l10n.profileExport,
      subtitle: l10n.profileExportSubtitle.toUpperCase(),
      trailing: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share, size: 16),
      onTap: _busy ? null : _export,
    );
  }
}
