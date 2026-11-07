import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/predictor.dart';

void main() {
  final now = DateTime(2026, 11, 5, 12);

  LaunchRecord rec(
    String pkg,
    String slot, {
    int daysAgo = 1,
    String day = 'workday',
  }) => LaunchRecord(
    ts: now.subtract(Duration(days: daysAgo)),
    package: pkg,
    features: {'slot': slot, 'daytype': day},
  );

  AppPredictor trained() => AppPredictor()
    ..addAll([
      for (var i = 0; i < 10; i++) rec('mail', 'morning', daysAgo: i + 1),
      for (var i = 0; i < 2; i++) rec('mail', 'evening', daysAgo: i + 1),
      for (var i = 0; i < 10; i++) rec('music', 'evening', daysAgo: i + 1),
      for (var i = 0; i < 2; i++) rec('music', 'morning', daysAgo: i + 1),
      rec('rare', 'morning'),
      rec('rare', 'morning'),
    ]);

  test('the order depends on the context', () {
    final p = trained();
    expect(
      p.top({'slot': 'morning', 'daytype': 'workday'}, now: now).first,
      'mail',
    );
    expect(
      p.top({'slot': 'evening', 'daytype': 'workday'}, now: now).first,
      'music',
    );
  });

  test('at least 3 launches are required', () {
    final s = trained().scores({'slot': 'morning'}, now: now);
    expect(s.containsKey('rare'), isFalse);
    expect(s.containsKey('mail'), isTrue);
  });

  test('unknown features are ignored', () {
    final p = trained();
    final withNull = p.scores({'slot': 'morning', 'place': null}, now: now);
    final without = p.scores({'slot': 'morning'}, now: now);
    expect(withNull['mail'], closeTo(without['mail']!, 1e-9));
  });

  test('decay weighs old launches less', () {
    final p = AppPredictor()
      ..addAll([
        for (var i = 0; i < 10; i++) rec('old', 'morning', daysAgo: 200 + i),
        for (var i = 0; i < 4; i++) rec('new', 'morning', daysAgo: 1 + i),
      ]);
    expect(p.top({'slot': 'morning'}, now: now).first, 'new');
  });

  test('filtered candidates', () {
    final s = trained().scores(
      {'slot': 'morning'},
      now: now,
      candidates: {'music'},
    );
    expect(s.keys, ['music']);
  });

  test('the explanation shows the direction', () {
    final p = trained();
    FeatureContribution slot(List<FeatureContribution> e) =>
        e.firstWhere((c) => c.feature == 'slot');
    expect(
      slot(p.explain('music', {'slot': 'evening'}, now: now)).delta,
      greaterThan(0),
    );
    expect(
      slot(p.explain('music', {'slot': 'morning'}, now: now)).delta,
      lessThan(0),
    );
  });

  group('frequency and recency', () {
    LaunchRecord at(String pkg, Duration ago) => LaunchRecord(
      ts: now.subtract(ago),
      package: pkg,
      features: const {'slot': 'morning'},
    );

    test('a just-used app rises, and the effect fades within hours', () {
      final p = AppPredictor(epoch: now)
        ..addAll([
          for (var i = 0; i < 20; i++) at('abituale', Duration(days: 2 + i)),
          for (var i = 0; i < 3; i++) at('nuova', Duration(minutes: 10 + i)),
          for (var i = 0; i < 3; i++) at('vecchia', Duration(days: 20 + i)),
        ]);
      const ctx = {'slot': 'morning'};
      final adesso = p.scores(ctx, now: now);
      // Frequency still beats a single recent use...
      expect(adesso['abituale']!, greaterThan(adesso['nuova']!));
      // ...but the just-used app beats one used long ago.
      expect(adesso['nuova']!, greaterThan(adesso['vecchia']!));
      // After two days the momentum has faded.
      final dopo = p.scores(ctx, now: now.add(const Duration(days: 2)));
      expect(adesso['nuova']! - dopo['nuova']!, greaterThan(1.0));
    });

    test('admitted with 1 recent launch, excluded if old', () {
      final p = AppPredictor(epoch: now)
        ..add(at('recente', const Duration(minutes: 10)))
        ..add(at('dimenticata', const Duration(days: 3)));
      final s = p.scores({'slot': 'morning'}, now: now);
      expect(s.containsKey('recente'), isTrue);
      expect(s.containsKey('dimenticata'), isFalse);
    });

    test('recency appears in the explanation', () {
      final p = AppPredictor(epoch: now)
        ..addAll([for (var i = 0; i < 3; i++) at('x', Duration(minutes: i))]);
      final r = p
          .explain('x', {'slot': 'morning'}, now: now)
          .firstWhere((c) => c.feature == 'recency');
      expect(r.delta, greaterThan(1));
    });

    test('removing a package leaves no trace', () {
      final p = trained()..removePackage('music');
      final s = p.scores({'slot': 'evening'}, now: now);
      expect(s.containsKey('music'), isFalse);
      expect(p.top({'slot': 'evening'}, now: now).first, 'mail');
    });

    test('shifting t0 does not change the scores', () {
      final far = now.add(const Duration(days: 200));
      final a = AppPredictor(epoch: now);
      final b = AppPredictor(epoch: far.subtract(const Duration(days: 1)));
      final rs = [
        for (var i = 0; i < 6; i++) at('x', Duration(days: -199 + i)),
        for (var i = 0; i < 4; i++) at('y', Duration(days: -198 + i)),
      ];
      a.addAll(rs);
      b.addAll(rs);
      final sa = a.scores({'slot': 'morning'}, now: far);
      final sb = b.scores({'slot': 'morning'}, now: far);
      expect(sa['x']!, closeTo(sb['x']!, 1e-6));
      expect(sa['y']!, closeTo(sb['y']!, 1e-6));
    });
  });

  test('launches without a signal do not penalize the app', () {
    // "imported" comes from Android's usage history (no network info);
    // "mobile" was always opened on mobile data. On Wi-Fi, "imported" must
    // not rank below "mobile" just because its network is unknown.
    final p = AppPredictor()
      ..addAll([
        for (var i = 0; i < 10; i++)
          LaunchRecord(
            ts: now.subtract(Duration(days: i + 1)),
            package: 'imported',
            features: const {'slot': 'morning', 'daytype': 'workday'},
          ),
        for (var i = 0; i < 10; i++)
          LaunchRecord(
            ts: now.subtract(Duration(days: i + 1)),
            package: 'mobile',
            features: const {
              'slot': 'morning',
              'daytype': 'workday',
              'network': 'mobile',
            },
          ),
      ]);
    final ctx = {'slot': 'morning', 'daytype': 'workday', 'network': 'wifi'};
    expect(p.top(ctx, now: now).first, 'imported');
  });
}
