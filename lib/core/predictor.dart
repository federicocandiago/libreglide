/// Previsione delle app: frequenza + recentezza + contesto
/// (spec-motore-contesto §7.2).
///
/// Per ogni app si tengono contatori che decadono nel tempo, aggiornati in
/// O(1) a ogni apertura senza rileggere lo storico:
///
/// - **abitudine** (emivita [habitHalfLife], 30 giorni): la frequenza;
/// - **slancio** (emivita [momentumHalfLife], 6 ore): la recentezza;
/// - per ogni feature di contesto (fascia, giorno, rete, cuffie, luogo…)
///   l'abitudine dell'app con quel valore.
///
/// Punteggio (Naive Bayes con smoothing di Laplace):
///
///   score(app | ctx) = log((H(app) + κ·M(app)) / (H_tot + κ·M_tot))
///       + Σ_f λ_f · log((H(app, f = ctx_f) + α) / (H(app) + α · |V_f|))
///
/// dove H è l'abitudine e M lo slancio. Un'app appena aperta vale per qualche
/// ora come 1 + κ aperture abituali, poi torna alla sua frequenza normale.
///
/// Trucco per l'O(1): ogni apertura al tempo t aggiunge e^{λ(t − t0)} invece
/// di aggiornare tutti i pesi; al momento del calcolo si divide per
/// e^{λ(now − t0)}. Quando gli esponenti crescono troppo si sposta t0.
library;

import 'dart:math' as math;

/// Un'apertura di app con le feature del contesto in cui è avvenuta.
class LaunchRecord {
  const LaunchRecord({
    required this.ts,
    required this.package,
    required this.features,
  });

  final DateTime ts;
  final String package;

  /// Valori per nome di feature (`slot`, `daytype`, `network`, `audio`,
  /// `place`, `motion`); null = sconosciuto.
  final Map<String, String?> features;
}

/// Contributo di un fattore al punteggio, per la diagnostica.
class FeatureContribution {
  const FeatureContribution(this.feature, this.value, this.delta);
  final String feature;
  final String value;

  /// log(P(valore | app) / P(valore)) per le feature; per `recency` il
  /// guadagno dovuto alle aperture recenti. Positivo = rende l'app più
  /// probabile.
  final double delta;

  @override
  String toString() =>
      '$feature=$value (${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)})';
}

/// Scala esponenziale condivisa da tutti i contatori con la stessa emivita.
class _Clock {
  _Clock(Duration halfLife, DateTime t0)
    : lambdaPerMs = math.ln2 / halfLife.inMilliseconds,
      t0Ms = t0.millisecondsSinceEpoch.toDouble();

  final double lambdaPerMs;
  double t0Ms;

  double exponent(DateTime t) =>
      lambdaPerMs * (t.millisecondsSinceEpoch - t0Ms);

  /// Peso da aggiungere per un evento al tempo [t].
  double weight(DateTime t) => math.exp(exponent(t));

  /// Fattore che riporta i valori salvati alla scala di [now].
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

  /// Numero di valori possibili per feature (|V_f|). Per `place` è una
  /// stima: home, work, altro, viaggio e alcuni luoghi frequenti.
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

  /// κ: quante aperture abituali vale un'apertura appena avvenuta.
  final double momentumBoost;
  final double alpha;

  /// Aperture minime perché un'app venga prevista, a meno che non sia stata
  /// usata di recente.
  final int minLaunches;
  final Map<String, double> weights;
  final Map<String, int> vocabularySizes;

  late final _Clock _habit;
  late final _Clock _momentum;

  // Valori nella scala di t0 (vedi _Clock).
  final Map<String, double> _appHabit = {};
  final Map<String, double> _appMomentum = {};
  final Map<String, int> _appRaw = {};
  final Map<String, Map<String, Map<String, double>>> _featHabit = {};
  final Map<String, Map<String, double>> _globalFeatHabit = {};
  double _totalHabit = 0;
  double _totalMomentum = 0;
  int _total = 0;

  /// Oltre questo esponente si sposta t0, per non uscire dai double.
  static const _maxExponent = 500.0;

  int get totalLaunches => _total;

  void add(LaunchRecord r) {
    _rebaseIfNeeded(r.ts);
    final wh = _habit.weight(r.ts);
    final wm = _momentum.weight(r.ts);
    final app = r.package;
    _appHabit[app] = (_appHabit[app] ?? 0) + wh;
    _appMomentum[app] = (_appMomentum[app] ?? 0) + wm;
    _appRaw[app] = (_appRaw[app] ?? 0) + 1;
    _totalHabit += wh;
    _totalMomentum += wm;
    _total++;
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

  /// Toglie un pacchetto (per esempio dopo una disinstallazione).
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

  /// Punteggi (log-probabilità non normalizzate) delle app prevedibili:
  /// almeno [minLaunches] aperture oppure usate nelle ultime ore.
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
        // Il confronto è con le sole aperture in cui il segnale era noto:
        // quelle importate dalla cronologia di Android non hanno rete,
        // luogo né audio e non devono penalizzare l'app.
        final hTot = _observed(_featHabit[app]?[f]) * nh;
        s += lambda * math.log((hf + alpha) / (hTot + alpha * vocab));
      });
      out[app] = s;
    }
    return out;
  }

  /// Peso delle aperture in cui una feature era nota.
  static double _observed(Map<String, double>? values) {
    if (values == null) return 0;
    var sum = 0.0;
    for (final w in values.values) {
      sum += w;
    }
    return sum;
  }

  /// Le [n] app più probabili nel contesto, dalla più probabile.
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

  /// Abitudine complessiva di ogni app (senza contesto), per riempire le
  /// liste quando le previsioni sono poche.
  Map<String, double> habit({DateTime? now}) {
    final nh = _habit.normalizer(now ?? DateTime.now());
    return {for (final e in _appHabit.entries) e.key: e.value * nh};
  }

  /// Spiega perché [app] ha quel punteggio nel contesto dato.
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
