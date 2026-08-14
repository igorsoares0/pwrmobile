import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The rest countdown between sets.
class RestTimerState {
  const RestTimerState({
    this.remaining = Duration.zero,
    this.total = Duration.zero,
    this.running = false,
  });

  final Duration remaining;
  final Duration total;
  final bool running;

  /// True once a rest has been started and not yet dismissed.
  bool get isActive => total > Duration.zero;

  bool get isFinished => isActive && remaining <= Duration.zero;

  /// Completion in 0..1, for the progress ring.
  double get progress {
    if (!isActive) return 0;
    return 1 -
        (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// Drives the rest countdown.
///
/// Deliberately *not* persisted. A rest timer is ephemeral coaching, not
/// training data: if the app is killed mid-rest the user has already been
/// resting for real, and restoring a stale countdown would be worse than
/// showing none. Everything that matters — the sets — is in the database.
class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _ticker;

  @override
  RestTimerState build() {
    // Without this the ticker outlives the screen, and in tests it trips the
    // binding's pending-timer assertion.
    ref.onDispose(_stopTicker);
    return const RestTimerState();
  }

  /// Starts a fresh countdown of [seconds].
  void start(int seconds) {
    _stopTicker();
    state = RestTimerState(
      remaining: Duration(seconds: seconds),
      total: Duration(seconds: seconds),
      running: true,
    );
    _startTicker();
  }

  void pause() {
    if (!state.running) return;
    _stopTicker();
    state = RestTimerState(remaining: state.remaining, total: state.total);
  }

  void resume() {
    if (state.running || !state.isActive || state.isFinished) return;
    state = RestTimerState(
      remaining: state.remaining,
      total: state.total,
      running: true,
    );
    _startTicker();
  }

  /// Adds time to a running or paused rest, for the set that needs more.
  void extend(int seconds) {
    if (!state.isActive) return;
    final added = Duration(seconds: seconds);
    state = RestTimerState(
      remaining: state.remaining + added,
      total: state.total + added,
      running: state.running,
    );
    if (state.running) _startTicker();
  }

  /// Dismisses the rest entirely.
  void skip() {
    _stopTicker();
    state = const RestTimerState();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remaining - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        _stopTicker();
        state = RestTimerState(total: state.total);
        return;
      }
      state = RestTimerState(
        remaining: remaining,
        total: state.total,
        running: true,
      );
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  RestTimerNotifier.new,
);
