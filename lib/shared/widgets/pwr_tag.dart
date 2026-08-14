import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Emphasis of a [PwrTag].
enum PwrTagTone {
  /// Selected filter, active marker: filled accent on white text.
  accent,

  /// Default: quiet surface fill on muted text.
  neutral,

  /// Outlined variant used over the app background, e.g. the gym-name chip.
  outlined,
}

/// A pill-shaped tag.
///
/// Covers muscle-group filters, the `SUPERSÉRIE` marker, previous-performance
/// hints, and the `3/3 NO FREE` counter. Text is mono because tags in PWR
/// almost always carry a number or a technical term.
class PwrTag extends StatelessWidget {
  const PwrTag(
    this.label, {
    super.key,
    this.tone = PwrTagTone.neutral,
    this.onTap,
    this.textStyle,
  });

  final String label;
  final PwrTagTone tone;
  final VoidCallback? onTap;

  /// Overrides the default mono tag style — pass an interface style for tags
  /// that read as words rather than data (muscle-group filters).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: (textStyle ?? PwrTypography.tag).copyWith(color: _foreground),
      ),
    );

    return Material(
      color: _background,
      shape: RoundedRectangleBorder(
        borderRadius: PwrRadius.pillAll,
        side: tone == PwrTagTone.outlined
            ? const BorderSide(color: PwrColors.border)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              highlightColor: Colors.transparent,
              child: content,
            ),
    );
  }

  Color get _background => switch (tone) {
    PwrTagTone.accent => PwrColors.accentStrong,
    PwrTagTone.neutral => PwrColors.surface,
    PwrTagTone.outlined => Colors.transparent,
  };

  Color get _foreground => switch (tone) {
    PwrTagTone.accent => PwrColors.onAccent,
    _ => PwrColors.textMuted,
  };
}
