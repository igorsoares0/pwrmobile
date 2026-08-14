import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

/// Body measurements. Phase 5 — the `BodyMeasurement` table does not exist yet.
class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PwrNotBuilt(
      title: l10n.bodyTitle,
      headline: l10n.bodyNotBuilt,
      body: l10n.bodyNotBuiltBody,
    );
  }
}
