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

  test("l'ordine dipende dal contesto", () {
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

  test('servono almeno 3 aperture', () {
    final s = trained().scores({'slot': 'morning'}, now: now);
    expect(s.containsKey('rare'), isFalse);
    expect(s.containsKey('mail'), isTrue);
  });

  test('le feature sconosciute vengono ignorate', () {
    final p = trained();
    final withNull = p.scores({'slot': 'morning', 'place': null}, now: now);
    final without = p.scores({'slot': 'morning'}, now: now);
    expect(withNull['mail'], closeTo(without['mail']!, 1e-9));
  });

  test('il decadimento pesa meno le aperture vecchie', () {
    final p = AppPredictor()
      ..addAll([
        for (var i = 0; i < 10; i++) rec('old', 'morning', daysAgo: 200 + i),
        for (var i = 0; i < 4; i++) rec('new', 'morning', daysAgo: 1 + i),
      ]);
    expect(p.top({'slot': 'morning'}, now: now).first, 'new');
  });

  test('candidati filtrati', () {
    final s = trained().scores(
      {'slot': 'morning'},
      now: now,
      candidates: {'music'},
    );
    expect(s.keys, ['music']);
  });

  test('la spiegazione indica la direzione', () {
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

  group('frequenza e recentezza', () {
    LaunchRecord at(String pkg, Duration ago) => LaunchRecord(
      ts: now.subtract(ago),
      package: pkg,
      features: const {'slot': 'morning'},
    );

    test("un'app appena usata sale, e l'effetto svanisce in poche ore", () {
      final p = AppPredictor(epoch: now)
        ..addAll([
          for (var i = 0; i < 20; i++) at('abituale', Duration(days: 2 + i)),
          for (var i = 0; i < 3; i++) at('nuova', Duration(minutes: 10 + i)),
          for (var i = 0; i < 3; i++) at('vecchia', Duration(days: 20 + i)),
        ]);
      const ctx = {'slot': 'morning'};
      final adesso = p.scores(ctx, now: now);
      // La frequenza resta più forte di un uso recente isolato...
      expect(adesso['abituale']!, greaterThan(adesso['nuova']!));
      // ...ma l'app appena usata supera quella usata tanto tempo fa.
      expect(adesso['nuova']!, greaterThan(adesso['vecchia']!));
      // Dopo due giorni lo slancio è svanito.
      final dopo = p.scores(ctx, now: now.add(const Duration(days: 2)));
      expect(adesso['nuova']! - dopo['nuova']!, greaterThan(1.0));
    });

    test('ammessa con 1 apertura recente, esclusa se vecchia', () {
      final p = AppPredictor(epoch: now)
        ..add(at('recente', const Duration(minutes: 10)))
        ..add(at('dimenticata', const Duration(days: 3)));
      final s = p.scores({'slot': 'morning'}, now: now);
      expect(s.containsKey('recente'), isTrue);
      expect(s.containsKey('dimenticata'), isFalse);
    });

    test('la recentezza compare nella spiegazione', () {
      final p = AppPredictor(epoch: now)
        ..addAll([for (var i = 0; i < 3; i++) at('x', Duration(minutes: i))]);
      final r = p
          .explain('x', {'slot': 'morning'}, now: now)
          .firstWhere((c) => c.feature == 'recency');
      expect(r.delta, greaterThan(1));
    });

    test('rimuovere un pacchetto non lascia tracce', () {
      final p = trained()..removePackage('music');
      final s = p.scores({'slot': 'evening'}, now: now);
      expect(s.containsKey('music'), isFalse);
      expect(p.top({'slot': 'evening'}, now: now).first, 'mail');
    });

    test('lo spostamento di t0 non cambia i punteggi', () {
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
}
