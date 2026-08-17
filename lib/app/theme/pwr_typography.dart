import 'package:flutter/painting.dart';

import 'pwr_colors.dart';

/// PWR typography.
///
/// Two families, with a strict division of labour:
///
/// * **Poppins** — everything a human reads as language: headings, labels,
///   descriptions, buttons.
/// * **Azeret Mono** — everything a human reads as a *number* or a technical
///   marker: weights, reps, timers, volume, section overlines, chips.
///
/// Keeping numbers monospaced means a set row does not reflow when the weight
/// goes from `9` to `10`, which matters because the set row is the screen the
/// user looks at most.
abstract final class PwrTypography {
  static const String interfaceFamily = 'Poppins';
  static const String monoFamily = 'AzeretMono';

  /// Poppins carries tall ascenders and descenders, so line heights stay at or
  /// above this even for nominally single-line styles.
  static const double _tightInterfaceHeight = 1.15;

  // --- Interface: display ---------------------------------------------------

  /// Onboarding headline.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.32,
    color: PwrColors.textPrimary,
  );

  /// Home greeting.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.28,
    color: PwrColors.textPrimary,
  );

  /// Workout summary headline.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.26,
    color: PwrColors.textPrimary,
  );

  /// Current exercise name during a workout.
  static const TextStyle headline = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: PwrColors.textPrimary,
  );

  /// The `PWR` wordmark. Wide tracking is part of the mark.
  static const TextStyle wordmark = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: _tightInterfaceHeight,
    letterSpacing: 3.08,
    color: PwrColors.textPrimary,
  );

  // --- Interface: titles ----------------------------------------------------

  /// Primary routine card title.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: PwrColors.textPrimary,
  );

  /// Screen title next to a back arrow.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: _tightInterfaceHeight,
    color: PwrColors.textPrimary,
  );

  /// Section heading inside a screen ("Suas rotinas").
  static const TextStyle titleSmall = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: _tightInterfaceHeight,
    color: PwrColors.textPrimary,
  );

  // --- Interface: body ------------------------------------------------------

  /// Multi-line explanatory copy.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: PwrColors.textPrimary,
  );

  /// List row title — an exercise name, a routine name.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: _tightInterfaceHeight,
    color: PwrColors.textPrimary,
  );

  /// Supporting sentence under a row title.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: PwrColors.textPrimary,
  );

  /// Smallest interface text: hints, secondary descriptions.
  static const TextStyle caption = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: PwrColors.textMuted,
  );

  // --- Interface: actions ---------------------------------------------------

  /// Label of a primary or secondary full-width button.
  static const TextStyle button = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: _tightInterfaceHeight,
    color: PwrColors.textPrimary,
  );

  /// Label of a compact inline button.
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: interfaceFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: _tightInterfaceHeight,
    color: PwrColors.textPrimary,
  );

  // --- Mono: metrics --------------------------------------------------------

  /// Hero number on the workout summary share card.
  static const TextStyle metricXl = TextStyle(
    fontFamily: monoFamily,
    fontSize: 46,
    fontWeight: FontWeight.w600,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textPrimary,
  );

  /// Rest timer countdown.
  static const TextStyle metricLg = TextStyle(
    fontFamily: monoFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textPrimary,
  );

  /// Stat tile value, elapsed session clock.
  static const TextStyle metricMd = TextStyle(
    fontFamily: monoFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textPrimary,
  );

  /// Weight and reps inside a set row. The most-read number in the app.
  static const TextStyle metricSm = TextStyle(
    fontFamily: monoFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textPrimary,
  );

  /// Inline value at the end of a row, e.g. a PR result.
  static const TextStyle metricXs = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textPrimary,
  );

  // --- Mono: labels ---------------------------------------------------------

  /// Section overline: `EXERCÍCIOS · 6`, `RECORDES DE HOJE`. Always uppercase.
  static const TextStyle overline = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 1.6,
    color: PwrColors.textMuted,
  );

  /// Widest overline, for the single most important label on a screen.
  static const TextStyle overlineWide = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 1.8,
    color: PwrColors.textMuted,
  );

  /// Set index column, small technical annotations.
  static const TextStyle label = TextStyle(
    fontFamily: monoFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    color: PwrColors.textMuted,
  );

  /// Chip and tag text: `SUPERSÉRIE`, `ANTERIOR 4×8 · 80KG`.
  static const TextStyle tag = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0.5,
    color: PwrColors.textMuted,
  );

  /// Two-line caption under a metric: `TREINOS\nNA SEMANA`.
  static const TextStyle metricCaption = TextStyle(
    fontFamily: monoFamily,
    fontSize: 9,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.9,
    color: PwrColors.textMuted,
  );

  /// Bottom navigation item label.
  ///
  /// 10px rather than the prototype's 9: at 9 the label is below any readable
  /// floor, and it is drawn in [PwrColors.textFaint], the palette's quietest
  /// colour. It does not go higher because the four labels share the row with
  /// the centre button — at 11px `HISTÓRICO` no longer fits its quarter on a
  /// 360dp screen. The tracking gives back the width the extra point costs.
  static const TextStyle navLabel = TextStyle(
    fontFamily: monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0.4,
    color: PwrColors.textFaint,
  );
}
