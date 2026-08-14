import 'package:flutter/widgets.dart';

import '../../app/theme/theme.dart';

/// The wide-tracked mono label that opens a section.
///
/// Examples: `TERÇA · SEMANA 12`, `EXERCÍCIOS · 6`, `RECORDES DE HOJE`.
/// The label is uppercased here so callers never have to remember to do it.
class PwrOverline extends StatelessWidget {
  const PwrOverline(
    this.label, {
    super.key,
    this.color,
    this.wide = false,
    this.trailing,
  });

  final String label;
  final Color? color;

  /// Uses the widest tracking. Reserve it for the single most important label
  /// on a screen.
  final bool wide;

  /// Optional widget pinned to the right of the label, e.g. a `3/3 NO FREE`
  /// counter or an "arraste para reordenar" hint.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = (wide ? PwrTypography.overlineWide : PwrTypography.overline)
        .copyWith(color: color);

    final text = Text(label.toUpperCase(), style: style);
    if (trailing == null) return text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [text, trailing!],
    );
  }
}
