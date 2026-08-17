import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/workout/active_session_bar.dart';
import 'pwr_bottom_nav.dart';

/// The tabbed frame the four main destinations live inside.
///
/// Uses go_router's indexed stack, so each tab keeps its own history: leaving
/// history for a session summary and coming back should land where the user
/// was, not at the top.
class PwrShell extends StatelessWidget {
  const PwrShell({
    super.key,
    required this.shell,
    this.onStartWorkout,
    this.onResumeWorkout,
  });

  final StatefulNavigationShell shell;
  final VoidCallback? onStartWorkout;

  /// Opens the session the bar is announcing.
  final void Function(String sessionId)? onResumeWorkout;

  /// Switches to a tab from anywhere inside the shell.
  static void goToBranch(BuildContext context, int index) {
    StatefulNavigationShell.of(context).goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      // The session bar rides with the navigation rather than inside the body,
      // so it survives every tab switch and never scrolls away.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActiveSessionBar(onResume: onResumeWorkout),
          PwrBottomNav(
            currentIndex: shell.currentIndex,
            // `initialLocation: true` when re-tapping the current tab pops it
            // back to its root, which is what a second tap is expected to do.
            onSelect: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            onStartWorkout: onStartWorkout,
          ),
        ],
      ),
    );
  }
}
