import 'package:flutter/widgets.dart';

/// Spacing scale. Prefer these over raw numbers so rhythm stays consistent.
abstract final class PwrSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double xxl = 40;

  /// Horizontal padding of every full-width screen.
  static const double screenH = 22;

  /// Top padding of a screen body, below the status bar.
  static const double screenTop = 18;

  /// Bottom padding of a scrollable screen body.
  static const double screenBottom = 24;

  /// Padding for a standard screen that is not inside a scroll view.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    screenH,
    screenTop,
    screenH,
    screenBottom,
  );

  /// Gap between stacked list rows (routines, exercises, sets).
  static const double listGap = 8;

  /// Gap between cards in a vertical stack.
  static const double cardGap = 10;
}

/// Corner radii.
abstract final class PwrRadius {
  /// Bars and tracks.
  static const Radius bar = Radius.circular(4);

  /// List rows and compact cards.
  static const Radius row = Radius.circular(16);

  /// Standard cards.
  static const Radius card = Radius.circular(20);

  /// Emphasis cards: rest timer, workout summary hero.
  static const Radius cardLarge = Radius.circular(24);

  /// Fully rounded: buttons, chips, tags, avatars.
  static const Radius pill = Radius.circular(999);

  static const BorderRadius barAll = BorderRadius.all(bar);
  static const BorderRadius rowAll = BorderRadius.all(row);
  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius cardLargeAll = BorderRadius.all(cardLarge);
  static const BorderRadius pillAll = BorderRadius.all(pill);
}

/// Motion. Kept short — logging a set must never feel like waiting.
abstract final class PwrDuration {
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
}
