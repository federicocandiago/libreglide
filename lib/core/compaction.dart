/// Compaction of the history (spec-motore-contesto §5 and §9): the database
/// stays small and fast without changing what the algorithms learn.
///
/// - **Launches and card taps**: rows are grouped per app and context, with
///   a count and an "equivalent" time chosen so that the decayed habit
///   weight is exactly the same as the original rows (see
///   [equivalentTime]), whatever the size of the period. Tiers: single rows
///   for 48 hours (the recency weight, half-life 6 hours, matters only
///   there: after 48 hours it is below 0.4%), then one group per day, and
///   after [dailyWindow] one group per month, until the retention limit.
/// - **Location samples**: they can't be aggregated (home and work come from
///   their sequence), so only redundant ones are removed; see [thinSamples].
library;

import 'dart:math' as math;

import 'predictor.dart';

/// Raw rows are kept this long before being compacted per day.
const Duration rawWindow = Duration(hours: 48);

/// Daily groups are kept this long before being merged per month.
const Duration dailyWindow = Duration(days: 30);

/// The single time whose decayed weight, times [counts]' sum, equals the
/// sum of the decayed weights of [times] (each with its count), for a decay
/// with the given [halfLife]. Exact, whatever "now" is.
DateTime equivalentTime(
  List<DateTime> times,
  List<int> counts,
  Duration halfLife,
) {
  assert(times.length == counts.length && times.isNotEmpty);
  final ref = times.reduce((a, b) => a.isBefore(b) ? a : b);
  final h = halfLife.inMilliseconds.toDouble();
  var sum = 0.0;
  var n = 0;
  for (var i = 0; i < times.length; i++) {
    final dt = times[i].difference(ref).inMilliseconds / h;
    sum += counts[i] * math.pow(2, dt);
    n += counts[i];
  }
  final offset = h * math.log(sum / n) / math.ln2;
  return ref.add(Duration(milliseconds: offset.round()));
}

/// One row per app (or card) and context: same features, summed counts,
/// equivalent time for [halfLife].
List<LaunchRecord> compactLaunches(
  List<LaunchRecord> rows, {
  required Duration halfLife,
}) {
  final groups = <String, List<LaunchRecord>>{};
  for (final r in rows) {
    final keys = r.features.keys.toList()..sort();
    final key = [
      r.package,
      for (final k in keys)
        if (r.features[k] != null) '$k=${r.features[k]}',
    ].join('|');
    groups.putIfAbsent(key, () => []).add(r);
  }
  return [
    for (final g in groups.values)
      LaunchRecord(
        ts: equivalentTime(
          [for (final r in g) r.ts],
          [for (final r in g) r.count],
          halfLife,
        ),
        package: g.first.package,
        features: g.first.features,
        count: g.fold(0, (n, r) => n + r.count),
      ),
  ];
}

/// The longest span between the two neighbors of a sample that can be
/// dropped: far below the 4-hour gaps used for sleep and visits.
const Duration thinSpan = Duration(minutes: 30);

/// Which samples to keep (same order as the input, sorted by time). A
/// sample is dropped only when the kept one before it and the one after it
/// are at the same place, on the same day, at most [thinSpan] apart. This
/// keeps every gap used for sleep (≥ 4 h), the visit durations (sums of
/// consecutive gaps at a place), the first and last sample of each day,
/// the first arrival at each place and the morning/afternoon presence.
List<bool> thinSamples(List<DateTime> ts, List<int?> placeOf) {
  final keep = List<bool>.filled(ts.length, true);
  if (ts.length < 3) return keep;
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  var prev = 0;
  for (var i = 1; i < ts.length - 1; i++) {
    final place = placeOf[i];
    final droppable =
        place != null &&
        placeOf[prev] == place &&
        placeOf[i + 1] == place &&
        sameDay(ts[prev], ts[i + 1]) &&
        ts[i + 1].difference(ts[prev]) <= thinSpan;
    if (droppable) {
      keep[i] = false;
    } else {
      prev = i;
    }
  }
  return keep;
}
