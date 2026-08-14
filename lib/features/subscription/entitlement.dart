import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the user is entitled to.
///
/// Phase 4 replaces this with RevenueCat's `pro` entitlement. Until then every
/// user is on the free plan, which is the honest default: showing PRO features
/// as unlocked before purchasing exists would be a lie the UI has to un-tell.
enum Entitlement {
  free,
  pro;

  bool get isPro => this == Entitlement.pro;

  /// How many routines the plan allows, or null for unlimited (spec §12/§13).
  int? get routineLimit => switch (this) {
    Entitlement.free => 3,
    Entitlement.pro => null,
  };

  /// Whether another routine can be created given [current] existing ones.
  bool canCreateRoutine(int current) {
    final limit = routineLimit;
    return limit == null || current < limit;
  }
}

/// The user's current entitlement.
///
/// Overridden by the subscription layer in Phase 4; RevenueCat remains the
/// source of truth, so nothing downstream should cache the result.
final entitlementProvider = Provider<Entitlement>((ref) => Entitlement.free);
