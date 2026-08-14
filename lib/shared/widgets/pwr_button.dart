import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// Visual weight of a [PwrButton].
enum PwrButtonVariant {
  /// Filled accent. One per screen — the action the user came to perform.
  primary,

  /// Outlined. The alternative path: "Já tenho conta", "Finalizar treino".
  secondary,

  /// Borderless text. Lowest emphasis, for dismissals and tertiary links.
  ghost,
}

/// Size of a [PwrButton].
enum PwrButtonSize {
  /// Full-width call to action.
  large,

  /// Inline action that sits next to content, e.g. "Liberar" on a PRO banner.
  compact,
}

/// The PWR button.
///
/// Always a pill. Full-width by default, because the primary actions in this
/// app are thumb targets pressed mid-set with sweaty hands.
class PwrButton extends StatelessWidget {
  const PwrButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PwrButtonVariant.primary,
    this.size = PwrButtonSize.large,
    this.icon,
    this.expand = true,
  });

  const PwrButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PwrButtonSize.large,
    this.icon,
    this.expand = true,
  }) : variant = PwrButtonVariant.secondary;

  const PwrButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PwrButtonSize.large,
    this.icon,
    this.expand = true,
  }) : variant = PwrButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final PwrButtonVariant variant;
  final PwrButtonSize size;
  final IconData? icon;

  /// Whether the button stretches to the width of its parent.
  final bool expand;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final isLarge = size == PwrButtonSize.large;

    final padding = isLarge
        ? const EdgeInsets.symmetric(vertical: 17, horizontal: PwrSpacing.lg)
        : const EdgeInsets.symmetric(vertical: 10, horizontal: PwrSpacing.md);

    final textStyle =
        (isLarge ? PwrTypography.button : PwrTypography.buttonSmall).copyWith(
          color: _foreground,
        );

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: isLarge ? 18 : 15, color: _foreground),
          const SizedBox(width: PwrSpacing.xs),
        ],
        Text(label, style: textStyle),
      ],
    );

    return Opacity(
      opacity: _enabled ? 1 : 0.4,
      child: Material(
        color: _background,
        shape: RoundedRectangleBorder(
          borderRadius: PwrRadius.pillAll,
          side: variant == PwrButtonVariant.secondary
              ? const BorderSide(color: PwrColors.borderStrong)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: _splash,
          highlightColor: _splash,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }

  Color get _background => switch (variant) {
    PwrButtonVariant.primary => PwrColors.accentStrong,
    PwrButtonVariant.secondary => Colors.transparent,
    PwrButtonVariant.ghost => Colors.transparent,
  };

  Color get _foreground => switch (variant) {
    PwrButtonVariant.primary => PwrColors.onAccent,
    PwrButtonVariant.secondary => PwrColors.textPrimary,
    PwrButtonVariant.ghost => PwrColors.textMuted,
  };

  Color get _splash => switch (variant) {
    PwrButtonVariant.primary => PwrColors.accentDeep,
    _ => PwrColors.surface,
  };
}
