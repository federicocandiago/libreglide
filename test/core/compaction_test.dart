import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/compaction.dart';
import 'package:libreglide/core/places.dart';
import 'package:libreglide/core/predictor.dart';
import 'package:libreglide/core/space_profile.dart';

import 'places_test.dart' show Spot, at, home, work, gym;

void main() {
  final now = DateTime(2026, 11, 30, 18);

  test('the equivalent time keeps the decayed weight exactly', () {
    const h = Duration(days: 30);
    final times = [
      DateTime(2026, 11, 2, 7, 5),
      DateTime(2026, 11, 2, 13, 40),
      DateTime(2026, 11, 2, 22, 59),
    ];
    final counts = [1, 3, 2];
    double w(DateTime t) =>
        math.pow(2, t.difference(now).inMilliseconds / h.inMilliseconds) * 1.0;
    final original = [for (var i = 0; i < 3; i++) counts[i] * w(times[i])]
        .reduce((a, b) => a + b);
    final t = equivalentTime(times, counts, h);
    expect(6 * w(t), closeTo(original, original * 1e-6));
    expect(t.isAfter(times.first) && t.isBefore(times.last), isTrue);
  });

  /// 60 days of launches, shaped like real use: a few apps make most of
  /// the openings, and most rows come from Android usage history (time slot
  /// and day type only); the rest are launcher openings with more context.
  List<LaunchRecord> history() {
    final rnd = math.Random(7);
    const apps = [
      'chat',
      'chat',
      'chat',
      'mail',
      'mail',
      'maps',
      'music',
      'news',
      'bank',
    ];
    const slots = ['morning', 'lunch', 'afternoon', 'evening'];
    const places = ['home', 'work', 'other', null];
    final out = <LaunchRecord>[];
    for (var d = 60; d >= 0; d--) {
      for (var i = 0; i < 30; i++) {
        final minute = rnd.nextInt(16 * 60);
        final ts = now.subtract(Duration(days: d, minutes: minute));
        final slot = slots[(minute ~/ 240).clamp(0, 3)];
        final daytype = ts.weekday >= 6 ? 'holiday' : 'workday';
        final fromLauncher = i % 4 == 0;
        out.add(
          LaunchRecord(
            ts: ts,
            package: apps[rnd.nextInt(apps.length)],
            features: fromLauncher
                ? {
                    'slot': slot,
                    'daytype': daytype,
                    'place': places[rnd.nextInt(places.length)],
                    'audio': rnd.nextBool() ? 'speaker' : null,
                  }
                : {'slot': slot, 'daytype': daytype},
          ),
        );
      }
    }
    return out..sort((a, b) => a.ts.compareTo(b.ts));
  }

  /// What the store does: raw rows in the last 48 hours, one group per day
  /// up to 30 days, then one per month (from the daily groups).
  List<LaunchRecord> compacted(List<LaunchRecord> rows, Duration halfLife) {
    final rawCutoff = now.subtract(rawWindow);
    final dailyCutoff = now.subtract(dailyWindow);
    final byDay = <String, List<LaunchRecord>>{};
    final raw = <LaunchRecord>[];
    for (final r in rows) {
      if (!r.ts.isBefore(rawCutoff)) {
        raw.add(r);
        continue;
      }
      byDay
          .putIfAbsent('${r.ts.year}-${r.ts.month}-${r.ts.day}', () => [])
          .add(r);
    }
    final daily = [
      for (final day in byDay.values)
        ...compactLaunches(day, halfLife: halfLife),
    ];
    final byMonth = <String, List<LaunchRecord>>{};
    final recent = <LaunchRecord>[];
    for (final r in daily) {
      if (!r.ts.isBefore(dailyCutoff)) {
        recent.add(r);
        continue;
      }
      byMonth.putIfAbsent('${r.ts.year}-${r.ts.month}', () => []).add(r);
    }
    return [
      for (final month in byMonth.values)
        ...compactLaunches(month, halfLife: halfLife),
      ...recent,
      ...raw,
    ];
  }

  test('predictions are the same after compaction', () {
    final rows = history();
    final small = compacted(rows, const Duration(days: 30));
    expect(small.length, lessThan(rows.length / 2));

    final a = AppPredictor()..addAll(rows);
    final b = AppPredictor()..addAll(small);
    expect(b.totalLaunches, a.totalLaunches);
    for (final ctx in [
      {'slot': 'morning', 'daytype': 'workday', 'place': 'work'},
      {'slot': 'evening', 'daytype': 'holiday', 'place': 'home'},
      {'slot': 'lunch', 'audio': 'speaker'},
    ]) {
      final sa = a.scores(ctx, now: now);
      final sb = b.scores(ctx, now: now);
      expect(sb.keys.toSet(), sa.keys.toSet());
      for (final app in sa.keys) {
        expect(sb[app], closeTo(sa[app]!, 0.01), reason: '$app in $ctx');
      }
      List<String> order(Map<String, double> s) =>
          s.keys.toList()..sort((x, y) => s[y]!.compareTo(s[x]!));
      expect(order(sb), order(sa));
    }
  });

  test('card affinity is the same after compaction', () {
    final rows = [
      for (final r in history())
        LaunchRecord(
          ts: r.ts,
          package: r.package == 'mail' ? 'agenda' : 'weather',
          features: r.features,
        ),
    ];
    final small = compacted(rows, const Duration(days: 21));
    final a = CardAffinity();
    final b = CardAffinity();
    for (final r in rows) {
      a.add(SpaceCard.values.byName(r.package), r.ts, r.features);
    }
    for (final r in small) {
      b.add(
        SpaceCard.values.byName(r.package),
        r.ts,
        r.features,
        count: r.count,
      );
    }
    for (final card in [SpaceCard.agenda, SpaceCard.weather]) {
      final ctx = {'slot': 'morning', 'place': 'work'};
      final x = a.affinity(card, now, ctx);
      expect(b.affinity(card, now, ctx), closeTo(x, x * 0.005));
    }
  });

  test('thinning samples leaves places and roles unchanged', () {
    // A dense trace: a sample every 5 minutes while at a place.
    List<LocationSample> denseDay(DateTime d) {
      final weekend = d.weekday >= DateTime.saturday;
      List<LocationSample> every5(int fromH, int toH, Spot s) => [
        for (var m = fromH * 60; m < toH * 60; m += 5)
          at(d, m ~/ 60, s, m: m % 60, charging: m < 7 * 60 + 10),
      ];
      return [
        ...every5(7, 8, home),
        if (!weekend) ...[
          ...every5(9, 18, work),
        ] else ...[
          ...every5(10, 12, home),
          ...every5(16, 18, gym),
        ],
        ...every5(19, 23, home),
      ];
    }

    final engine = PlaceEngine();
    final samples = <LocationSample>[];
    final placeOf = <int?>[];
    final start = DateTime(2026, 11, 2);
    for (var i = 0; i < 28; i++) {
      for (final s in denseDay(start.add(Duration(days: i)))) {
        samples.add(s);
        placeOf.add(engine.addSample(s));
      }
    }
    final end = DateTime(2026, 11, 29, 23, 59);
    engine.inferRoles(samples, placeOf, end);
    final roles = {for (final p in engine.places) p.id: p.role};
    final scores = {...engine.scores};
    final kind = engine.workKind;

    final keep = thinSamples([for (final s in samples) s.ts], placeOf);
    final thinS = [
      for (var i = 0; i < samples.length; i++)
        if (keep[i]) samples[i],
    ];
    final thinP = [
      for (var i = 0; i < samples.length; i++)
        if (keep[i]) placeOf[i],
    ];
    expect(thinS.length, lessThan(samples.length / 4));

    engine.inferRoles(thinS, thinP, end);
    expect({for (final p in engine.places) p.id: p.role}, roles);
    expect(engine.workKind, kind);
    for (final id in scores.keys) {
      final before = scores[id]!, after = engine.scores[id]!;
      expect(after.homeConfidence, closeTo(before.homeConfidence, 1e-9));
      expect(after.workConfidence, closeTo(before.workConfidence, 1e-9));
      expect(after.days, before.days);
    }
    expect(near(engine.withRole(PlaceRole.home), home), isTrue);
    expect(near(engine.withRole(PlaceRole.work), work), isTrue);
  });
}

bool near(Place? p, Spot s) =>
    p != null && distanceMeters(p.lat, p.lon, s.$1, s.$2) < 150;
