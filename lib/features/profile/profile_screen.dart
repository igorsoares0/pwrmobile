import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/widgets.dart';

/// Account and settings. Phase 2 brings Firebase Auth; there is nothing to
/// show until then.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PwrNotBuilt(
      title: l10n.profileTitle,
      headline: l10n.profileNotBuilt,
      body: l10n.profileNotBuiltBody,
    );
  }
}
