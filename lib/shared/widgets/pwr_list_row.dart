import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import 'pwr_card.dart';

/// The workhorse row: a title, a mono subtitle, and a chevron.
///
/// Used for exercises in the library, secondary routines on the home screen,
/// and settings entries. Keeping it in one place is what stops the app from
/// drifting into four slightly different list styles.
class PwrListRow extends StatelessWidget {
  const PwrListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const Icon(Icons.arrow_forward, size: 16),
    this.onTap,
    this.dashed = false,
    this.accentBar = false,
    this.subtitleColor,
  });

  /// Locked or not-yet-created content: dashed outline, muted text.
  const PwrListRow.placeholder({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing = const Icon(Icons.arrow_forward, size: 16),
    this.onTap,
    this.subtitleColor,
  }) : dashed = true,
       accentBar = false;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Renders with a dashed outline instead of a filled surface.
  final bool dashed;

  /// Marks the row as part of a superset.
  final bool accentBar;

  /// Overrides the subtitle color — use [PwrColors.accent] to call out a
  /// superset, [PwrColors.danger] for a warning.
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: PwrSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: PwrTypography.bodyMedium.copyWith(
                  color: dashed ? PwrColors.textMuted : PwrColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  style: PwrTypography.tag.copyWith(color: subtitleColor),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          IconTheme.merge(
            data: const IconThemeData(color: PwrColors.textMuted, size: 16),
            child: trailing!,
          ),
      ],
    );

    const padding = EdgeInsets.symmetric(
      horizontal: 18,
      vertical: PwrSpacing.md,
    );

    if (dashed) {
      return PwrCard.dashed(
        onTap: onTap,
        padding: padding,
        borderRadius: PwrRadius.rowAll,
        child: content,
      );
    }

    return PwrCard(
      onTap: onTap,
      padding: padding,
      borderRadius: PwrRadius.rowAll,
      leadingAccentBar: accentBar,
      child: content,
    );
  }
}
