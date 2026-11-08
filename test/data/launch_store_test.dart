import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/places.dart';
import 'package:libreglide/core/predictor.dart';
import 'package:libreglide/data/launch_store.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final file = File(p.join(await getDatabasesPath(), 'libreglide.db'));
    if (file.existsSync()) file.deleteSync();
  });

  final now = DateTime(2026, 11, 30, 18);

  /// 100 days of launches (40 a day, mostly from usage history) and card
  /// taps.
  Future<List<LaunchRecord>> fill(LaunchStore store) async {
    final rnd = math.Random(3);
    const apps = ['chat', 'chat', 'chat', 'mail', 'maps', 'music', 'bank'];
    const slots = ['morning', 'lunch', 'afternoon', 'evening'];
    final usage = <LaunchRecord>[];
    for (var d = 100; d >= 0; d--) {
      for (var i = 0; i < 40; i++) {
        final minute = rnd.nextInt(16 * 60);
        final ts = now.subtract(Duration(days: d, minutes: minute));
        usage.add(
          LaunchRecord(
            ts: ts,
            package: apps[rnd.nextInt(apps.length)],
            features: {
              'slot': slots[(minute ~/ 240).clamp(0, 3)],
              'daytype': ts.weekday >= 6 ? 'holiday' : 'workday',
            },
          ),
        );
      }
      await store.insert(
        LaunchRecord(
          ts: now.subtract(Duration(days: d, hours: 2)),
          package: 'agenda',
          features: const {'slot': 'morning', 'place': 'work'},
        ),
        source: 'card',
      );
    }
    await store.insertAll(usage, 'usage');
    return usage;
  }

  Future<void> maintainAll(LaunchStore store) async {
    var steps = 0;
    while (await store.maintainStep(now)) {
      steps++;
      expect(steps, lessThan(1000));
    }
    await store.prune(now);
  }

  test('maintenance compacts, keeps the counts and the predictions', () async {
    final store = await LaunchStore.open();
    addTearDown(store.close);
    final usage = await fill(store);
    final (before, _) = await store.rowCounts();

    final reference = AppPredictor()
      ..addAll(
        usage.where(
          (r) => r.ts.isAfter(now.subtract(const Duration(days: 150))),
        ),
      );

    await maintainAll(store);
    final (after, _) = await store.rowCounts();
    expect(after, lessThan(before / 3));

    // The launches still count the same (SUM of n, not rows).
    final counts = await store.countBySource();
    expect(counts['usage'], usage.length);
    expect(counts['card'], 101);

    // The last 48 hours are untouched, single rows.
    final raw = await store.rawSince();
    expect(raw, isNotNull);
    expect(raw!.isAfter(now.subtract(const Duration(days: 3))), isTrue);

    final loaded = await store.loadAndPrune(now: now);
    final rebuilt = AppPredictor()..addAll(loaded);
    for (final ctx in [
      {'slot': 'morning', 'daytype': 'workday'},
      {'slot': 'evening', 'daytype': 'holiday'},
    ]) {
      final a = reference.scores(ctx, now: now);
      final b = rebuilt.scores(ctx, now: now);
      for (final app in a.keys) {
        expect(b[app], closeTo(a[app]!, 0.02), reason: '$app $ctx');
      }
    }

    // A second run has nothing left to do.
    expect(await store.maintainStep(now), isFalse);
  });

  test('retention: nothing older than 180 days, samples after 30', () async {
    final store = await LaunchStore.open();
    addTearDown(store.close);
    await store.insert(
      LaunchRecord(
        ts: now.subtract(const Duration(days: 200)),
        package: 'old',
        features: const {},
      ),
    );
    await store.insert(
      LaunchRecord(
        ts: now.subtract(const Duration(days: 10)),
        package: 'recent',
        features: const {},
      ),
    );
    for (final days in [40, 5]) {
      await store.insertSample(
        LocationSample(ts: now.subtract(Duration(days: days))),
        null,
      );
    }
    await maintainAll(store);
    final loaded = await store.loadAndPrune(now: now);
    expect(loaded.map((r) => r.package), ['recent']);
    final (_, samples) = await store.rowCounts();
    expect(samples, 1);
  });
}
