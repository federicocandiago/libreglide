import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/app_entry.dart';
import 'package:libreglide/core/categories.dart';
import 'package:libreglide/core/collections.dart';

AppEntry app(String pkg, [String? label]) =>
    AppEntry(packageName: pkg, activityName: '.Main', label: label ?? pkg);

void main() {
  // 3 music apps, 3 messaging, 1 finance (small → Other).
  final music = [app('m.a', 'Alfa'), app('m.b', 'Beta'), app('m.c', 'Gamma')];
  final chat = [
    app('c.a', 'Chat A'),
    app('c.b', 'Chat B'),
    app('c.c', 'Chat C'),
  ];
  final bank = app('f.a', 'Banca');
  final apps = [...music, ...chat, bank];
  final categoryOf = {
    for (final a in music) a.id: AppCategory.music,
    for (final a in chat) a.id: AppCategory.messaging,
    bank.id: AppCategory.finance,
  };

  List<AppCategory> cats(List<CollectionGroup> g) => [
    for (final x in g) x.category,
  ];
  List<String> pkgs(CollectionGroup g) => [
    for (final a in g.ranked) a.packageName,
  ];

  test('small categories merge into Other', () {
    final g = CollectionsBuilder().build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => {},
      contextKey: 'k',
      revision: 0,
      totalLaunches: 0,
    );
    expect(cats(g), [
      AppCategory.messaging,
      AppCategory.music,
      AppCategory.other,
    ]);
    expect(pkgs(g.last), ['f.a']);
  });

  test('a pinned category stays on top and is not merged', () {
    final g = CollectionsBuilder().build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => {},
      contextKey: 'k',
      revision: 0,
      totalLaunches: 0,
      pinned: [AppCategory.finance],
    );
    expect(g.first.category, AppCategory.finance);
    expect(g.first.pinned, isTrue);
  });

  test('hidden categories disappear', () {
    final g = CollectionsBuilder().build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => {},
      contextKey: 'k',
      revision: 0,
      totalLaunches: 0,
      hidden: {AppCategory.music},
    );
    expect(cats(g).contains(AppCategory.music), isFalse);
  });

  test('with enough data, categories are sorted by score', () {
    final g = CollectionsBuilder().build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => {'m.a': -1.0, 'c.a': -5.0},
      contextKey: 'k',
      revision: 0,
      totalLaunches: 100,
    );
    expect(g.first.category, AppCategory.music);
    expect(pkgs(g.first).first, 'm.a');
  });

  test('in the same context the order does not change', () {
    final b = CollectionsBuilder();
    var scores = {'m.a': -1.0, 'm.b': -2.0};
    List<CollectionGroup> build(String key) => b.build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => scores,
      contextKey: key,
      revision: 0,
      totalLaunches: 100,
    );
    final first = build('mattina');
    expect(
      pkgs(first.firstWhere((g) => g.category == AppCategory.music)).take(2),
      ['m.a', 'm.b'],
    );
    scores = {'m.a': -3.0, 'm.b': -0.5};
    final same = build('mattina');
    expect(
      pkgs(same.firstWhere((g) => g.category == AppCategory.music)).take(2),
      ['m.a', 'm.b'],
    );
    final next = build('sera');
    expect(
      pkgs(next.firstWhere((g) => g.category == AppCategory.music)).take(2),
      ['m.b', 'm.a'],
    );
  });

  test('hysteresis: a small difference does not swap', () {
    final b = CollectionsBuilder();
    List<String> musicOrder(Map<String, double> s, String key) => pkgs(
      b
          .build(
            apps: apps,
            categoryOf: categoryOf,
            scores: () => s,
            contextKey: key,
            revision: 0,
            totalLaunches: 100,
          )
          .firstWhere((g) => g.category == AppCategory.music),
    );
    expect(musicOrder({'m.a': -1.0, 'm.b': -1.2}, 'k1').take(2), [
      'm.a',
      'm.b',
    ]);
    // m.b beats m.a by 0.05 < ln(1.1) ≈ 0.095: it stays put.
    expect(musicOrder({'m.a': -1.0, 'm.b': -0.95}, 'k2').take(2), [
      'm.a',
      'm.b',
    ]);
    // m.b beats m.a by 0.5: they swap.
    expect(musicOrder({'m.a': -1.0, 'm.b': -0.5}, 'k3').take(2), [
      'm.b',
      'm.a',
    ]);
  });

  test('fixed order: alphabetical and default category order', () {
    final g = CollectionsBuilder().build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => {'m.c': 0.0},
      contextKey: 'k',
      revision: 0,
      totalLaunches: 100,
      fixedOrder: true,
    );
    expect(cats(g), [
      AppCategory.messaging,
      AppCategory.music,
      AppCategory.other,
    ]);
    expect(pkgs(g[1]), ['m.a', 'm.b', 'm.c']);
  });

  test('a new app in the same context goes last without reordering', () {
    final b = CollectionsBuilder();
    final s = {'m.b': -1.0, 'm.a': -2.0};
    b.build(
      apps: apps,
      categoryOf: categoryOf,
      scores: () => s,
      contextKey: 'k',
      revision: 0,
      totalLaunches: 100,
    );
    final extra = app('m.z', 'Zeta');
    final g = b.build(
      apps: [...apps, extra],
      categoryOf: {...categoryOf, extra.id: AppCategory.music},
      scores: () => {...s, 'm.z': 5.0},
      contextKey: 'k',
      revision: 1,
      totalLaunches: 100,
    );
    final musicGroup = g.firstWhere((x) => x.category == AppCategory.music);
    expect(pkgs(musicGroup).take(2), ['m.b', 'm.a']);
    expect(musicGroup.ranked.map((a) => a.packageName), contains('m.z'));
  });

  test('row and rest: the rest is alphabetical', () {
    final g = CollectionGroup(
      category: AppCategory.music,
      ranked: [
        app('z', 'Zeta'),
        app('a', 'Alfa'),
        app('m', 'Emme'),
        app('b', 'Bi'),
      ],
      pinned: false,
    );
    expect(g.row(2).map((a) => a.label), ['Zeta', 'Alfa']);
    expect(g.rest(2).map((a) => a.label), ['Bi', 'Emme']);
  });

  test('stableReorder without history sorts by score', () {
    final r = stableReorder<String>(
      previous: const [],
      current: ['a', 'b', 'c'],
      score: (x) => {'a': 1.0, 'b': 3.0, 'c': 2.0}[x]!,
      tieBreak: (x, y) => x.compareTo(y),
    );
    expect(r, ['b', 'c', 'a']);
  });
}
