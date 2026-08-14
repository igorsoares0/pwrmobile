import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/widgets.dart';
import '../workout/summary_providers.dart';
import 'share_card.dart';
import 'share_service.dart';

/// Shows the card before it leaves the device.
///
/// The user sees exactly the image that will be shared, rather than finding out
/// in the share sheet — which is also why the card is captured from the
/// on-screen boundary instead of being rendered off in the dark.
class SharePreviewSheet extends ConsumerStatefulWidget {
  const SharePreviewSheet({super.key, required this.summary});

  final WorkoutSummary summary;

  static Future<void> show(BuildContext context, WorkoutSummary summary) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SharePreviewSheet(summary: summary),
    );
  }

  @override
  ConsumerState<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends ConsumerState<SharePreviewSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final bytes = await captureBoundary(_cardKey);
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
        return;
      }

      final stats = widget.summary.stats;
      await ref
          .read(shareServiceProvider)
          .shareImage(
            bytes,
            fileName: 'pwr-${stats.session.id}.png',
            subject: l10n.shareSubject(
              widget.summary.routineName ?? l10n.shareCardFreestyle,
              formatLoad(stats.volume, locale, compact: false).value,
            ),
          );

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
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
              Text(l10n.sharePreviewTitle, style: PwrTypography.titleMedium),
              const SizedBox(height: PwrSpacing.md),

              // Scaled to fit the sheet, captured at its own fixed size: what
              // is exported does not depend on how much room the sheet had.
              Center(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ShareCard(summary: widget.summary),
                  ),
                ),
              ),

              const SizedBox(height: PwrSpacing.lg),
              PwrButton(
                label: l10n.shareConfirm,
                onPressed: _busy ? null : _share,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
