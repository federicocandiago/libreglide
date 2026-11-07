/// Builds the Collections with a stable order
/// (spec-viste-app §3).
library;

import 'dart:math' as math;

import 'app_entry.dart';
import 'categories.dart';

class CollectionGroup {
  const CollectionGroup({
    required this.category,
    required this.ranked,
    required this.pinned,
  });

  final AppCategory category;

  /// All apps in the group: scored ones first (context order with
  /// hysteresis), then the others in alphabetical order.
  /// The UI shows the first N in the row and the rest alphabetically.
  final List<AppEntry> ranked;
  final bool pinned;

  /// Apps in the dynamic row.
  List<AppEntry> row(int size) => ranked.take(size).toList();

  /// Apps in the expanded part: all except the row, in alphabetical order.
  List<AppEntry> rest(int size) {
    final inRow = row(size).toSet();
    final others = ranked.where((a) => !inRow.contains(a)).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return others;
  }
}

/// Hysteresis margin: an item overtakes the previous one only if its (log)
/// score is higher by at least ln(1.1), i.e. by 10%.
final double hysteresisMargin = math.log(1.1);

/// Below this total launch count the default order is used.
const int minLaunchesForDynamicOrder = 20;

/// Categories with at most this many apps are merged into Other.
const int smallCategoryThreshold = 2;

/// Reorders [current] starting from the [previous] order, moving an item
/// ahead of the previous one only if it beats it by [margin].
List<T> stableReorder<T>({
  required List<T> previous,
  required List<T> current,
  required double Function(T) score,
  required int Function(T, T) tieBreak,
  double margin = 0,
}) {
  final currentSet = current.toSet();
  int byScore(T a, T b) {
    final c = score(b).compareTo(score(a));
    return c != 0 ? c : tieBreak(a, b);
  }

  if (previous.isEmpty) return [...current]..sort(byScore);

  final previousSet = previous.toSet();
  final base = <T>[
    ...previous.where(currentSet.contains),
    ...(current.where((e) => !previousSet.contains(e)).toList()..sort(byScore)),
  ];
  for (var i = 1; i < base.length; i++) {
    var j = i;
    while (j > 0 && score(base[j]) > score(base[j - 1]) + margin) {
      final tmp = base[j];
      base[j] = base[j - 1];
      base[j - 1] = tmp;
      j--;
    }
  }
  return base;
}

/// Keeps state between builds, so the order changes only when the context
/// changes.
class CollectionsBuilder {
  String? _lastContextKey;
  int? _lastRevision;
  bool? _lastFixed;
  List<CollectionGroup> _last = const [];
  List<AppCategory> _categoryOrder = const [];
  final Map<AppCategory, List<AppEntry>> _appOrder = {};

  List<CollectionGroup> get current => _last;

  /// Builds the groups.
  ///
  /// - [scores]: predictor scores per package (log), computed only when a
  ///   rebuild is needed. Apps without a score go last, in alphabetical
  ///   order.
  /// - [revision]: must be incremented when installed apps, categories,
  ///   pinned or hidden items change.
  /// - The order is recomputed only if [contextKey] or [fixedOrder]
  ///   changes or [force] is true; if only [revision] changes, the previous
  ///   order is kept and new items go last.
  List<CollectionGroup> build({
    required List<AppEntry> apps,
    required Map<String, AppCategory> categoryOf,
    required Map<String, double> Function() scores,
    required String contextKey,
    required int revision,
    required int totalLaunches,
    bool fixedOrder = false,
    List<AppCategory> pinned = const [],
    Set<AppCategory> hidden = const {},
    Map<AppCategory, double> boosts = const {},
    bool force = false,
  }) {
    final contextChanged = contextKey != _lastContextKey;
    final modeChanged = fixedOrder != _lastFixed;
    if (!force &&
        !contextChanged &&
        !modeChanged &&
        revision == _lastRevision) {
      return _last;
    }
    final reorder = force || contextChanged || modeChanged;
    final scoreMap = scores();
    final dynamicOrder =
        !fixedOrder && totalLaunches >= minLaunchesForDynamicOrder;

    // 1. Group, dropping hidden categories.
    final groups = <AppCategory, List<AppEntry>>{};
    for (final app in apps) {
      final cat = categoryOf[app.id] ?? AppCategory.other;
      if (hidden.contains(cat)) continue;
      groups.putIfAbsent(cat, () => []).add(app);
    }

    // 2. Small unpinned categories are merged into Other.
    final small = groups.entries
        .where(
          (e) =>
              e.key != AppCategory.other &&
              !pinned.contains(e.key) &&
              !boosts.containsKey(e.key) &&
              e.value.length <= smallCategoryThreshold,
        )
        .map((e) => e.key)
        .toList();
    if (!hidden.contains(AppCategory.other)) {
      for (final cat in small) {
        groups.putIfAbsent(AppCategory.other, () => []).addAll(groups[cat]!);
        groups.remove(cat);
      }
    }

    double appScore(AppEntry a) =>
        scoreMap[a.packageName] ?? double.negativeInfinity;
    int alpha(AppEntry a, AppEntry b) {
      final c = a.sortKey.compareTo(b.sortKey);
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    // 3. App order within each group.
    final newAppOrder = <AppCategory, List<AppEntry>>{};
    groups.forEach((cat, list) {
      if (fixedOrder) {
        newAppOrder[cat] = [...list]..sort(alpha);
        return;
      }
      final prev = _appOrder[cat] ?? const [];
      if (reorder) {
        newAppOrder[cat] = stableReorder(
          previous: prev,
          current: list,
          score: appScore,
          tieBreak: alpha,
          margin: hysteresisMargin,
        );
      } else {
        newAppOrder[cat] = _keepOrder(prev, list, alpha);
      }
    });

    // 4. Category order.
    int defaultIndex(AppCategory c) => defaultCategoryOrder.indexOf(c);
    int byDefault(AppCategory a, AppCategory b) =>
        defaultIndex(a).compareTo(defaultIndex(b));
    final unpinned = groups.keys.where((c) => !pinned.contains(c)).toList();
    List<AppCategory> orderedUnpinned;
    // Collections with the initial boost come first, strongest on top.
    int byBoostThenDefault(AppCategory a, AppCategory b) {
      final c = (boosts[b] ?? 0).compareTo(boosts[a] ?? 0);
      return c != 0 ? c : byDefault(a, b);
    }

    if (!dynamicOrder) {
      orderedUnpinned = unpinned..sort(byBoostThenDefault);
    } else {
      double usage(AppCategory c) {
        final s = groups[c]!.map(appScore).where((v) => v.isFinite).toList()
          ..sort((a, b) => b.compareTo(a));
        if (s.isEmpty) return double.negativeInfinity;
        final top = s.take(3);
        return top.reduce((a, b) => a + b) / top.length;
      }

      // A boosted collection with no data yet starts from the lowest score
      // among the used ones, so the boost always has an effect.
      final finite = [
        for (final c in unpinned)
          if (usage(c).isFinite) usage(c),
      ];
      final floor = finite.isEmpty ? -30.0 : finite.reduce(math.min) - 1;
      double catScore(AppCategory c) {
        final boost = boosts[c];
        final u = usage(c);
        if (boost == null) return u;
        return (u.isFinite ? u : floor) + boost;
      }

      final prev = _categoryOrder.where((c) => !pinned.contains(c)).toList();
      orderedUnpinned = reorder
          ? stableReorder(
              previous: prev,
              current: unpinned,
              score: catScore,
              tieBreak: byDefault,
              margin: hysteresisMargin,
            )
          : _keepOrder(prev, unpinned, byDefault);
    }
    final order = [...pinned.where(groups.containsKey), ...orderedUnpinned];

    _categoryOrder = order;
    _appOrder
      ..clear()
      ..addAll(newAppOrder);
    _lastContextKey = contextKey;
    _lastRevision = revision;
    _lastFixed = fixedOrder;
    _last = [
      for (final cat in order)
        CollectionGroup(
          category: cat,
          ranked: fixedOrder
              ? newAppOrder[cat]!
              : _scoredFirst(newAppOrder[cat]!, appScore, alpha),
          pinned: pinned.contains(cat),
        ),
    ];
    return _last;
  }

  /// Keeps the previous order; new items go last.
  static List<T> _keepOrder<T>(
    List<T> previous,
    List<T> current,
    int Function(T, T) tieBreak,
  ) {
    final currentSet = current.toSet();
    final previousSet = previous.toSet();
    return [
      ...previous.where(currentSet.contains),
      ...(current.where((e) => !previousSet.contains(e)).toList()
        ..sort(tieBreak)),
    ];
  }

  /// Apps without a score always come after the scored ones, in
  /// alphabetical order.
  static List<AppEntry> _scoredFirst(
    List<AppEntry> list,
    double Function(AppEntry) score,
    int Function(AppEntry, AppEntry) alpha,
  ) {
    final scored = list.where((a) => score(a).isFinite).toList();
    final unscored = list.where((a) => !score(a).isFinite).toList()
      ..sort(alpha);
    return [...scored, ...unscored];
  }
}
