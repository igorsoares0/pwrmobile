import 'package:flutter/widgets.dart';

/// PWR color palette.
///
/// The product is dark-first: there is a single palette and no light variant.
/// Values are taken from the clickable prototype so the app stays visually
/// consistent with it.
abstract final class PwrColors {
  // --- Surfaces -------------------------------------------------------------

  /// App background. Everything sits on top of this.
  static const Color background = Color(0xFF121212);

  /// Default raised surface: cards, list rows, inputs, chips.
  static const Color surface = Color(0xFF1C1C1C);

  /// Subtle fills that must read above [surface]: progress tracks, dividers
  /// that need weight, quiet borders.
  static const Color surfaceRaised = Color(0xFF2A2A2A);

  /// Purple-tinted surfaces used behind accent content (PRO blocks, banners).
  static const Color surfaceAccent = Color(0xFF1E1526);
  static const Color surfaceAccentRaised = Color(0xFF33244A);

  // --- Borders --------------------------------------------------------------

  /// Hairlines, dividers and dashed placeholder outlines.
  static const Color border = Color(0xFF2A2A2A);

  /// Border of interactive-but-quiet elements, e.g. secondary buttons.
  static const Color borderStrong = Color(0xFF3A3A3A);

  /// Border used when an accent element needs containment without a full fill.
  static const Color borderAccent = Color(0xFF4A2668);

  // --- Text -----------------------------------------------------------------

  /// Primary reading color.
  static const Color textPrimary = Color(0xFFE6E4E4);

  /// Secondary text: technical labels, captions, inactive states.
  static const Color textMuted = Color(0xFF9A9A9A);

  /// Lowest-emphasis text: placeholders, drag handles, inactive nav icons.
  static const Color textFaint = Color(0xFF6E6E6E);

  /// Text and icons drawn on top of [accentStrong].
  static const Color onAccent = Color(0xFFFFFFFF);

  // --- Accent ---------------------------------------------------------------

  /// Highlight accent. Numbers, active nav, PRs, timers — anything that should
  /// read as "this is your progress".
  static const Color accent = Color(0xFFB06AE8);

  /// Action accent. Filled buttons, the primary routine card, the FAB.
  static const Color accentStrong = Color(0xFF8B2FC9);

  /// Pressed / deepest step of the accent ramp.
  static const Color accentDeep = Color(0xFF6D24A0);

  // --- Semantic -------------------------------------------------------------

  /// Failure sets, destructive actions, errors.
  static const Color danger = Color(0xFFFF6B6B);

  // --- Set type accents -----------------------------------------------------

  /// Warm-up sets — deliberately the same hue as [accent] but read as a
  /// preparatory marker, not a record.
  static const Color setWarmup = accent;

  /// Working sets carry no color of their own; they use [textPrimary].
  static const Color setNormal = textPrimary;

  /// Sets taken to failure.
  static const Color setFailure = danger;

  /// Drop sets.
  static const Color setDropSet = Color(0xFFB06AE8);
}
