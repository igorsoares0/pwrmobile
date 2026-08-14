import 'package:flutter/widgets.dart';

import '../../app/theme/theme.dart';

/// A single metric: a big mono number over a small mono caption.
///
/// ```
/// 18.4t
/// VOLUME
/// TOTAL
/// ```
class PwrStat extends StatelessWidget {
  const PwrStat({
    super.key,
    required this.value,
    required this.caption,
    this.unit,
    this.valueColor,
    this.captionColor,
    this.valueStyle,
  });

  /// The number itself, already formatted for display.
  final String value;

  /// Label under the number. Uppercased automatically; use `\n` to wrap it
  /// across two lines exactly where you want the break.
  final String caption;

  /// Small suffix rendered right after [value] at a reduced size, e.g. `t`,
  /// `KG`, `MIN`.
  final String? unit;

  final Color? valueColor;
  final Color? captionColor;

  /// Defaults to [PwrTypography.metricMd]. Pass a larger metric style for hero
  /// figures.
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedValueStyle = (valueStyle ?? PwrTypography.metricMd).copyWith(
      color: valueColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            children: [
              if (unit != null)
                TextSpan(
                  text: unit,
                  style: resolvedValueStyle.copyWith(
                    fontSize: resolvedValueStyle.fontSize! * 0.45,
                    color: captionColor ?? PwrColors.textMuted,
                  ),
                ),
            ],
          ),
          style: resolvedValueStyle,
        ),
        const SizedBox(height: PwrSpacing.xs),
        Text(
          caption.toUpperCase(),
          style: PwrTypography.metricCaption.copyWith(color: captionColor),
        ),
      ],
    );
  }
}

/// A row of [PwrStat]s laid out on an even grid.
///
/// Used for the home summary card and the workout summary hero.
class PwrStatRow extends StatelessWidget {
  const PwrStatRow({super.key, required this.stats, this.spacing = 10});

  final List<PwrStat> stats;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: stats[i]),
        ],
      ],
    );
  }
}
