import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// A destination in the bottom navigation.
class PwrNavItem {
  const PwrNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The bottom navigation from the prototype: four destinations around a raised
/// action in the middle.
///
/// The centre button is not a destination — it starts a workout. Giving the
/// product's main verb the most reachable spot on the screen is the whole point
/// of the layout, and making it a tab would have buried it.
class PwrBottomNav extends StatelessWidget {
  const PwrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.onStartWorkout,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Material outlined icons rather than the prototype's bespoke line set:
    // every other screen already uses them, so a second icon language here
    // would read as less consistent, not more faithful.
    final items = <PwrNavItem>[
      PwrNavItem(icon: Icons.fitness_center, label: l10n.navWorkout),
      PwrNavItem(icon: Icons.bar_chart, label: l10n.navHistory),
      PwrNavItem(icon: Icons.straighten, label: l10n.navBody),
      PwrNavItem(icon: Icons.person_outline, label: l10n.navProfile),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PwrColors.background,
        border: Border(top: BorderSide(color: PwrColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Destination(item: items[0], index: 0, nav: this),
              ),
              Expanded(
                child: _Destination(item: items[1], index: 1, nav: this),
              ),
              SizedBox(
                width: 74,
                // `heightFactor: 1` is load-bearing. A bare `Center` has no
                // height factor, so it grows to the tallest constraint it is
                // offered — and a bottom bar is offered the whole screen. The
                // bar would then cover everything above it.
                child: Align(
                  heightFactor: 1,
                  child: _StartButton(
                    onPressed: onStartWorkout,
                    tooltip: l10n.navStartWorkout,
                  ),
                ),
              ),
              Expanded(
                child: _Destination(item: items[2], index: 2, nav: this),
              ),
              Expanded(
                child: _Destination(item: items[3], index: 3, nav: this),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.index,
    required this.nav,
  });

  final PwrNavItem item;
  final int index;
  final PwrBottomNav nav;

  @override
  Widget build(BuildContext context) {
    final selected = nav.currentIndex == index;
    final color = selected ? PwrColors.accent : PwrColors.textFaint;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => nav.onSelect(index),
        borderRadius: PwrRadius.rowAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PwrSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(height: 6),
              // The longest label ("histórico") is within a hair of its quarter
              // of the bar on a narrow phone. Fading beats the debug stripes
              // and beats a second line that would grow the whole bar.
              Text(
                item.label.toUpperCase(),
                style: PwrTypography.navLabel.copyWith(color: color),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.tooltip, this.onPressed});

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: PwrColors.accentStrong,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: PwrColors.accentStrong.withValues(alpha: 0.7),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              // Play, not plus. `WorkoutLauncher.startOrResume` hands back the
              // open session when there is one, so a `+` promised "create" and
              // delivered "go back to what you were doing".
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 26,
                color: PwrColors.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
