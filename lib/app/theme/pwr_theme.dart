import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pwr_colors.dart';
import 'pwr_spacing.dart';
import 'pwr_typography.dart';

/// Assembles the PWR tokens into a Material [ThemeData].
///
/// Material widgets are used sparingly, but anything that *is* Material (text
/// fields, dialogs, snack bars, ink effects) must not fall back to the default
/// purple-seeded scheme, so the scheme is spelled out explicitly rather than
/// generated from a seed color.
abstract final class PwrTheme {
  /// The only theme. PWR is dark-first and ships no light variant.
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: PwrColors.accentStrong,
      onPrimary: PwrColors.onAccent,
      primaryContainer: PwrColors.accentDeep,
      onPrimaryContainer: PwrColors.onAccent,
      secondary: PwrColors.accent,
      onSecondary: PwrColors.onAccent,
      secondaryContainer: PwrColors.surfaceAccentRaised,
      onSecondaryContainer: PwrColors.textPrimary,
      // Spelled out even though it currently equals the Material default —
      // the palette must not silently follow a framework default that changes.
      // ignore: avoid_redundant_argument_values
      surface: PwrColors.background,
      onSurface: PwrColors.textPrimary,
      surfaceContainer: PwrColors.surface,
      surfaceContainerHigh: PwrColors.surfaceRaised,
      onSurfaceVariant: PwrColors.textMuted,
      outline: PwrColors.border,
      outlineVariant: PwrColors.borderStrong,
      error: PwrColors.danger,
      onError: PwrColors.onAccent,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: PwrColors.background,
      fontFamily: PwrTypography.interfaceFamily,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme,
      primaryTextTheme: _textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: PwrColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: PwrTypography.titleMedium,
        iconTheme: IconThemeData(color: PwrColors.textMuted, size: 22),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: PwrColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: PwrColors.border,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: PwrColors.textMuted, size: 22),

      // Text fields are used for weight/reps entry, so they stay flat and
      // borderless — the surrounding set row already provides the container.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PwrColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PwrSpacing.md,
          vertical: PwrSpacing.sm,
        ),
        hintStyle: PwrTypography.bodySmall.copyWith(color: PwrColors.textFaint),
        border: const OutlineInputBorder(
          borderRadius: PwrRadius.rowAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: PwrRadius.rowAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: PwrRadius.rowAll,
          borderSide: BorderSide(color: PwrColors.accentStrong),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: PwrRadius.rowAll,
          borderSide: BorderSide(color: PwrColors.danger),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PwrColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: PwrColors.textFaint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: PwrRadius.cardLarge),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: PwrColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: PwrTypography.titleMedium,
        contentTextStyle: PwrTypography.bodySmall.copyWith(
          color: PwrColors.textMuted,
        ),
        shape: const RoundedRectangleBorder(borderRadius: PwrRadius.cardAll),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: PwrColors.surfaceRaised,
        contentTextStyle: PwrTypography.bodySmall,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: PwrRadius.rowAll),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PwrColors.accentStrong,
        linearTrackColor: PwrColors.surfaceRaised,
        circularTrackColor: PwrColors.surfaceRaised,
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: PwrColors.accentStrong,
        inactiveTrackColor: PwrColors.surfaceRaised,
        thumbColor: PwrColors.accent,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(PwrColors.textPrimary),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? PwrColors.accentStrong
              : PwrColors.surfaceRaised;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // The workout screen is a long scroll the user thumbs through between
      // sets; an overscroll glow on a near-black background reads as a smudge.
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: PwrTypography.displayLarge,
    displayMedium: PwrTypography.displayMedium,
    displaySmall: PwrTypography.displaySmall,
    headlineLarge: PwrTypography.headline,
    headlineMedium: PwrTypography.headline,
    headlineSmall: PwrTypography.titleLarge,
    titleLarge: PwrTypography.titleLarge,
    titleMedium: PwrTypography.titleMedium,
    titleSmall: PwrTypography.titleSmall,
    bodyLarge: PwrTypography.bodyLarge,
    bodyMedium: PwrTypography.bodyMedium,
    bodySmall: PwrTypography.bodySmall,
    labelLarge: PwrTypography.button,
    labelMedium: PwrTypography.buttonSmall,
    labelSmall: PwrTypography.caption,
  );
}
