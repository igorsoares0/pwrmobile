import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pwrmobile/core/database/app_database.dart';
import 'package:pwrmobile/core/database/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late BodyRepository body;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    body = BodyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime daysAgo(int days) =>
      DateTime.now().toUtc().subtract(Duration(days: days));

  group('logging', () {
    test('an entry carries the sync metadata every entity has', () async {
      final entry = await body.log(weightKg: 82.4);

      expect(entry.weightKg, 82.4);
      expect(entry.version, 1);
      expect(entry.deletedAt, isNull);
      expect(entry.id, isNotEmpty);
    });

    test('a correction bumps the version rather than replacing the row', () async {
      final entry = await body.log(weightKg: 8.24);

      // The number people actually mistype: a misplaced decimal point.
      await body.update(entry.id, weightKg: 82.4);
      final fixed = await body.findById(entry.id);

      expect(fixed!.weightKg, 82.4);
      expect(fixed.version, 2);
      expect(fixed.id, entry.id);
    });

    test('a removed entry is tombstoned, not deleted', () async {
      final entry = await body.log(weightKg: 82.4);
      await body.remove(entry.id);

      // Gone from every user-facing read...
      expect(await body.findById(entry.id), isNull);

      // ...but the row survives, so phase 3 has a tombstone to replicate and
      // another device cannot resurrect it on its next pull.
      final raw = await db
          .customSelect('SELECT deleted_at FROM body_measurements')
          .getSingle();
      expect(raw.read<DateTime?>('deleted_at'), isNotNull);
    });

    test('measuredAt can predate the entry, for a catch-up weigh-in', () async {
      final saturday = daysAgo(2);
      final entry = await body.log(weightKg: 80, measuredAt: saturday);

      // Typed on Monday, belongs to Saturday. Storing the typing date instead
      // would bend the trend line.
      expect(
        entry.measuredAt.difference(saturday).inSeconds.abs(),
        lessThan(2),
      );
    });
  });

  group('trend', () {
    test('no entries means no trend', () async {
      expect(await body.watchTrend().first, isNull);
    });

    test('a single entry has no baseline to compare against', () async {
      await body.log(weightKg: 82.4);

      final trend = await body.watchTrend().first;

      // Not a delta of zero: "+0.0 kg" reads as "no progress" where the truth
      // is "nothing to compare yet".
      expect(trend!.deltaKg, isNull);
      expect(trend.latest.weightKg, 82.4);
    });

    test('the delta runs from the oldest entry inside the window', () async {
      await body.log(weightKg: 80.6, measuredAt: daysAgo(60));
      await body.log(weightKg: 81.5, measuredAt: daysAgo(30));
      await body.log(weightKg: 82.4, measuredAt: daysAgo(1));

      final trend = await body.watchTrend().first;

      expect(trend!.deltaKg, closeTo(1.8, 1e-9));
      expect(trend.spanWeeks, 8);
    });

    test('an entry older than the window is not the baseline', () async {
      await body.log(weightKg: 95, measuredAt: daysAgo(400));
      await body.log(weightKg: 80.6, measuredAt: daysAgo(60));
      await body.log(weightKg: 82.4, measuredAt: daysAgo(1));

      final trend = await body.watchTrend().first;

      // A weigh-in from last year is not "recent progress"; comparing against
      // it would report a 12.6 kg loss the user made over a year.
      expect(trend!.deltaKg, closeTo(1.8, 1e-9));
    });

    test('a loss reports a negative delta', () async {
      await body.log(weightKg: 84, measuredAt: daysAgo(21));
      await body.log(weightKg: 81.2, measuredAt: daysAgo(1));

      final trend = await body.watchTrend().first;

      expect(trend!.deltaKg, closeTo(-2.8, 1e-9));
      expect(trend.spanWeeks, 2);
    });

    test('a deleted entry stops counting immediately', () async {
      await body.log(weightKg: 80, measuredAt: daysAgo(30));
      final typo = await body.log(weightKg: 820, measuredAt: daysAgo(1));

      await body.remove(typo.id);
      final trend = await body.watchTrend().first;

      expect(trend!.latest.weightKg, 80);
      expect(trend.deltaKg, isNull);
    });
  });

  group('ordering', () {
    test('entries come back by measurement date, not by id', () async {
      // Inserted newest-first, which is the order the ids will sort in.
      await body.log(weightKg: 82.4, measuredAt: daysAgo(1));
      await body.log(weightKg: 80.6, measuredAt: daysAgo(30));

      final entries = await body.watchMeasurements().first;

      // The list has to lead with the most recent *weigh-in*, or a user
      // catching up on last week's number sees it jump to the top.
      expect(entries.map((e) => e.weightKg), [82.4, 80.6]);
    });
  });
}
