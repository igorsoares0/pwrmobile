import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pwr_bottom_nav.dart';

/// The tabbed frame the four main destinations live inside.
///
/// Uses go_router's indexed stack, so each tab keeps its own history: leaving
/// history for a session summary and coming back should land where the user
/// was, not at the top.
class PwrShell extends StatelessWidget {
  const PwrShell({super.key, required this.shell, this.onStartWorkout});

  final StatefulNavigationShell shell;
  final VoidCallback? onStartWorkout;

  /// Switches to a tab from anywhere inside the shell.
  static void goToBranch(BuildContext context, int index) {
    StatefulNavigationShell.of(context).goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: PwrBottomNav(
        currentIndex: shell.currentIndex,
        // `initialLocation: true` when re-tapping the current tab pops it back
        // to its root, which is what a second tap on a tab is expected to do.
        onSelect: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        onStartWorkout: onStartWorkout,
      ),
    );
  }
}
