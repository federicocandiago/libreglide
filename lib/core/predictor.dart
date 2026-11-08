/// App prediction: frequency + recency + context
/// (spec-motore-contesto §7.2).
///
/// Each app keeps counters that decay over time, updated in O(1) on every
/// launch without re-reading the history:
///
/// - **habit** (half-life [habitHalfLife], 30 days): the frequency;
/// - **momentum** (half-life [momentumHalfLife], 6 hours): the recency;
/// - for each context feature (slot, day type, network, headphones,
///   place…) the app's habit with that value.
///
/// Score (Naive Bayes with Laplace smoothing):
///
///   score(app | ctx) = log((H(app) + κ·M(app)) / (H_tot + κ·M_tot))
///       + Σ_f λ_f · log((H(app, f = ctx_f) + α) / (H_f(app) + α · |V_f|))
///
/// where H is the habit, M the momentum and H_f(app) the app's habit over
/// the launches where feature f was known (launches imported from Android
/// usage history have no network, place or audio and must not penalize the
/// app). An app just launched counts for
/// a few hours as 1 + κ habitual launches, then falls back to its normal
/// frequency.
///
/// The O(1) trick: each launch at time t adds e^{λ(t − t0)} instead of
/// updating all weights; at scoring time the result is divided by
/// e^{λ(now − t0)}. When the exponents grow too large, t0 is moved.
library;

import 'dart:math' as math;

/// An app launch with the features of the context it happened in.
class LaunchRecord {
  const LaunchRecord({
    required this.ts,
    required this.package,
    required this.features,
    this.count = 1,
  });

  final DateTime ts;
  final String package;

  /// How many launches this row stands for (more than 1 once the history
  /// is compacted, see compaction.dart).
  final int count;

  /// Values by feature name (`slot`, `daytype`, `network`, `audio`,
  /// `place`, `motion`); null = unknown.
  final Map<String, String?> features;
}

/// A factor's contribution to the score, for diagnostics.
class FeatureContribution {
  const FeatureContribution(this.feature, this.value, this.delta);
  final String feature;
  final String value;

  /// log(P(value | app) / P(value)) for features; for `recency`, the gain
  /// from recent launches. Positive = makes the app more likely.
  final double delta;

  @override
  String toString() =>
      '$feature=$value (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)})';
}

/// Exponential scale shared by all counters with the same half-life.
class _Clock {
  _Clock(Duration halfLife, DateTime t0)
    : lambdaPerMs = math.ln2 / halfLife.inMilliseconds,
      t0Ms = t0.millisecondsSinceEpoch.toDouble();

  final double lambdaPerMs;
  double t0Ms;

  double exponent(DateTime t) =>
      lambdaPerMs * (t.millisecondsSinceEpoch - t0Ms);

  /// Weight to add for an event at time [t].
  double weight(DateTime t) => math.exp(exponent(t));

  /// Factor that brings stored values to the scale of [now].
  double normalizer(DateTime now) => math.exp(-exponent(now));
}

class AppPredictor {
  AppPredictor({
    this.habitHalfLife = const Duration(days: 30),
    this.momentumHalfLife = const Duration(hours: 6),
    this.momentumBoost = 3.0,
    this.alpha = 1.0,
    this.minLaunches = 3,
    Map<String, double>? weights,
    Map<String, int>? vocabularySizes,
    DateTime? epoch,
  }) : weights = weights ?? defaultWeights,
       vocabularySizes = vocabularySizes ?? defaultVocabularySizes {
    final t0 = epoch ?? DateTime.now();
    _habit = _Clock(habitHalfLife, t0);
    _momentum = _Clock(momentumHalfLife, t0);
  }

  static const defaultWeights = <String, double>{
    'slot': 1.0,
    'place': 1.0,
    'network': 0.8,
    'daytype': 0.5,
    'audio': 0.8,
    'motion': 0.8,
  };

  /// Number of possible values per feature (|V_f|). For `place` it is an
  /// estimate: home, work, other, travel and a few frequent places.
  static const defaultVocabularySizes = <String, int>{
    'slot': 6,
    'daytype': 2,
    'network': 3,
    'place': 8,
    'audio': 3,
    'motion': 3,
  };

  final Duration habitHalfLife;
  final Duration momentumHalfLife;

  /// κ: how many habitual launches a just-happened launch is worth.
  final double momentumBoost;
  final double alpha;

  /// Minimum launches for an app to be predicted, unless it was used
  /// recently.
  final int minLaunches;
  final Map<String, double> weights;
  final Map<String, int> vocabularySizes;

  late final _Clock _habit;
  late final _Clock _momentum;

  // Values on the t0 scale (see _Clock).
  final Map<String, double> _appHabit = {};
  final Map<String, double> _appMomentum = {};
  final Map<String, int> _appRaw = {};
  final Map<String, Map<String, Map<String, double>>> _featHabit = {};
  final Map<String, Map<String, double>> _globalFeatHabit = {};
  double _totalHabit = 0;
  double _totalMomentum = 0;
  int _total = 0;

  /// Above this exponent t0 is moved, to stay within double range.
  static const _maxExponent = 500.0;

  int get totalLaunches => _total;

  void add(LaunchRecord r) {
    _rebaseIfNeeded(r.ts);
    final wh = _habit.weight(r.ts) * r.count;
    final wm = _momentum.weight(r.ts) * r.count;
    final app = r.package;
    _appHabit[app] = (_appHabit[app] ?? 0) + wh;
    _appMomentum[app] = (_appMomentum[app] ?? 0) + wm;
    _appRaw[app] = (_appRaw[app] ?? 0) + r.count;
    _totalHabit += wh;
    _totalMomentum += wm;
    _total += r.count;
    final perApp = _featHabit.putIfAbsent(app, () => {});
    r.features.forEach((f, v) {
      if (v == null) return;
      final perFeature = perApp.putIfAbsent(f, () => {});
      perFeature[v] = (perFeature[v] ?? 0) + wh;
      final global = _globalFeatHabit.putIfAbsent(f, () => {});
      global[v] = (global[v] ?? 0) + wh;
    });
  }

  void addAll(Iterable<LaunchRecord> rs) {
    for (final r in rs) {
      add(r);
    }
  }

  void clear() {
    _appHabit.clear();
    _appMomentum.clear();
    _appRaw.clear();
    _featHabit.clear();
    _globalFeatHabit.clear();
    _totalHabit = 0;
    _totalMomentum = 0;
    _total = 0;
  }

  /// Removes a package (e.g. after an uninstall).
  void removePackage(String package) {
    _totalHabit -= _appHabit.remove(package) ?? 0;
    _totalMomentum -= _appMomentum.remove(package) ?? 0;
    _total -= _appRaw.remove(package) ?? 0;
    final perApp = _featHabit.remove(package);
    perApp?.forEach((f, values) {
      final global = _globalFeatHabit[f];
      if (global == null) return;
      values.forEach((v, w) => global[v] = (global[v] ?? 0) - w);
    });
  }

  void _rebaseIfNeeded(DateTime t) {
    for (final clock in [_habit, _momentum]) {
      if (clock.exponent(t) < _maxExponent) continue;
      final factor = math.exp(-clock.exponent(t));
      void scale(Map<String, double> m) => m.updateAll((_, v) => v * factor);
      if (identical(clock, _habit)) {
        scale(_appHabit);
        for (final perApp in _featHabit.values) {
          perApp.values.forEach(scale);
        }
        _globalFeatHabit.values.forEach(scale);
        _totalHabit *= factor;
      } else {
        scale(_appMomentum);
        _totalMomentum *= factor;
      }
      clock.t0Ms = t.millisecondsSinceEpoch.toDouble();
    }
  }

  /// Scores (unnormalized log-probabilities) of the predictable apps: at
  /// least [minLaunches] launches, or used in the last few hours.
  Map<String, double> scores(
    Map<String, String?> context, {
    DateTime? now,
    Set<String>? candidates,
  }) {
    final t = now ?? DateTime.now();
    final nh = _habit.normalizer(t);
    final nm = _momentum.normalizer(t);
    final out = <String, double>{};
    final total = _totalHabit * nh + momentumBoost * _totalMomentum * nm;
    if (total <= 0) return out;

    for (final entry in _appHabit.entries) {
      final app = entry.key;
      if (candidates != null && !candidates.contains(app)) continue;
      final h = entry.value * nh;
      final m = (_appMomentum[app] ?? 0) * nm;
      if ((_appRaw[app] ?? 0) < minLaunches && m < 0.5) continue;
      var s = math.log((h + momentumBoost * m) / total);
      context.forEach((f, v) {
        if (v == null) return;
        final lambda = weights[f];
        final vocab = vocabularySizes[f];
        if (lambda == null || vocab == null) return;
        final hf = (_featHabit[app]?[f]?[v] ?? 0) * nh;
        // Compare only against launches where the signal was known: those
        // imported from Android usage history have no network, place or
        // audio and must not penalize the app.
        final hTot = _observed(_featHabit[app]?[f]) * nh;
        s += lambda * math.log((hf + alpha) / (hTot + alpha * vocab));
      });
      out[app] = s;
    }
    return out;
  }

  /// Weight of the launches in which a feature was known.
  static double _observed(Map<String, double>? values) {
    if (values == null) return 0;
    var sum = 0.0;
    for (final w in values.values) {
      sum += w;
    }
    return sum;
  }

  /// The [n] most likely apps in the context, most likely first.
  List<String> top(
    Map<String, String?> context, {
    int n = 5,
    DateTime? now,
    Set<String>? candidates,
  }) {
    final s = scores(context, now: now, candidates: candidates);
    final ranked = s.keys.toList()
      ..sort((a, b) {
        final c = s[b]!.compareTo(s[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return ranked.take(n).toList();
  }

  /// Overall habit of each app (without context), to fill lists when there
  /// are few predictions.
  Map<String, double> habit({DateTime? now}) {
    final nh = _habit.normalizer(now ?? DateTime.now());
    return {for (final e in _appHabit.entries) e.key: e.value * nh};
  }

  /// Explains why [app] has its score in the given context.
  List<FeatureContribution> explain(
    String app,
    Map<String, String?> context, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final nh = _habit.normalizer(t);
    final nm = _momentum.normalizer(t);
    final stored = _appHabit[app];
    if (stored == null || _totalHabit <= 0) return const [];
    final h = stored * nh;
    final m = (_appMomentum[app] ?? 0) * nm;
    final out = <FeatureContribution>[
      if (h > 0)
        FeatureContribution(
          'recency',
          m.toStringAsFixed(1),
          math.log((h + momentumBoost * m) / h),
        ),
    ];
    context.forEach((f, v) {
      if (v == null) return;
      final vocab = vocabularySizes[f];
      final lambda = weights[f];
      if (vocab == null || lambda == null) return;
      final hf = (_featHabit[app]?[f]?[v] ?? 0) * nh;
      final gf = (_globalFeatHabit[f]?[v] ?? 0) * nh;
      final hTot = _observed(_featHabit[app]?[f]) * nh;
      final gTot = _observed(_globalFeatHabit[f]) * nh;
      final pGivenApp = (hf + alpha) / (hTot + alpha * vocab);
      final pGlobal = (gf + alpha) / (gTot + alpha * vocab);
      out.add(
        FeatureContribution(f, v, lambda * math.log(pGivenApp / pGlobal)),
      );
    });
    out.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return out;
  }
}
