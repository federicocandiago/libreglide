import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/app_entry.dart';
import 'package:libreglide/core/boost.dart';
import 'package:libreglide/core/categories.dart';
import 'package:libreglide/core/collections.dart';

AppEntry app(String pkg) =>
    AppEntry(packageName: pkg, activityName: '.Main', label: pkg);

void main() {
  group('boostFactor', () {
    test('pieno per le prime 3 settimane', () {
      expect(boostFactor(Duration.zero), 1);
      expect(boostFactor(const Duration(days: 21)), 1);
    });

    test('poi si dimezza ogni 3 settimane', () {
      expect(boostFactor(const Duration(days: 42)), closeTo(0.5, 1e-9));
      expect(boostFactor(const Duration(days: 63)), closeTo(0.25, 1e-9));
    });

    test('le spinte esaurite spariscono', () {
      final created = DateTime(2026, 1, 1);
      final b = CategoryBoost(category: AppCategory.music, created: created);
      expect(activeBoosts([b], created).keys, [AppCategory.music]);
      expect(
        activeBoosts([b], created.add(const Duration(days: 400))),
        isEmpty,
      );
    });
  });

  group('Raccolte con spinta', () {
    final music = [app('m.a'), app('m.b'), app('m.c')];
    final chat = [app('c.a'), app('c.b'), app('c.c')];
    final games = [app('g.a'), app('g.b'), app('g.c')];
    final apps = [...music, ...chat, ...games];
    final categoryOf = {
      for (final a in music) a.id: AppCategory.music,
      for (final a in chat) a.id: AppCategory.messaging,
      for (final a in games) a.id: AppCategory.games,
    };
    List<AppCategory> order(List<CollectionGroup> g) => [
      for (final x in g) x.category,
    ];

    test('pochi dati: le preferite prima dell\'ordine predefinito', () {
      final g = CollectionsBuilder().build(
        apps: apps,
        categoryOf: categoryOf,
        scores: () => {},
        contextKey: 'k',
        revision: 0,
        totalLaunches: 0,
        boosts: {AppCategory.games: initialBoost},
      );
      expect(order(g), [
        AppCategory.games,
        AppCategory.messaging,
        AppCategory.music,
      ]);
    });

    test('con dati: la preferita senza aperture resta in cima nel plateau', () {
      final g = CollectionsBuilder().build(
        apps: apps,
        categoryOf: categoryOf,
        scores: () => {'m.a': -1.0, 'c.a': -2.0},
        contextKey: 'k',
        revision: 0,
        totalLaunches: 100,
        boosts: {AppCategory.games: initialBoost},
      );
      expect(order(g).first, AppCategory.games);
    });

    test('a spinta esaurita torna a contare solo l\'uso', () {
      final g = CollectionsBuilder().build(
        apps: apps,
        categoryOf: categoryOf,
        scores: () => {'m.a': -1.0, 'c.a': -2.0, 'g.a': -6.0},
        contextKey: 'k',
        revision: 0,
        totalLaunches: 100,
        boosts: {AppCategory.games: 0.06},
      );
      expect(order(g), [
        AppCategory.music,
        AppCategory.messaging,
        AppCategory.games,
      ]);
    });

    test('una preferita piccola non finisce in Altro', () {
      final solo = app('f.a');
      final g = CollectionsBuilder().build(
        apps: [...apps, solo],
        categoryOf: {...categoryOf, solo.id: AppCategory.finance},
        scores: () => {},
        contextKey: 'k',
        revision: 0,
        totalLaunches: 0,
        boosts: {AppCategory.finance: initialBoost},
      );
      expect(order(g).first, AppCategory.finance);
    });
  });
}
