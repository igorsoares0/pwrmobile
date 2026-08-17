import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/repositories/repositories.dart';

/// Every weigh-in, newest first.
final measurementsProvider = StreamProvider<List<BodyMeasurement>>(
  (ref) => ref.watch(bodyRepositoryProvider).watchMeasurements(),
);

/// Current weight and how far it has moved, for the header card.
///
/// A separate stream over the same query rather than a derivation of
/// [measurementsProvider]: drift shares the underlying watch, and the header
/// then rebuilds on its own terms instead of on every list change.
final bodyTrendProvider = StreamProvider<BodyTrend?>(
  (ref) => ref.watch(bodyRepositoryProvider).watchTrend(),
);
