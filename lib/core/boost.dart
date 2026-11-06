/// Spinta iniziale delle raccolte preferite scelte nell'onboarding.
///
/// Per le prime settimane le preferite restano in cima ("plateau"), poi la
/// spinta si dimezza a intervalli regolari e lascia spazio all'uso reale.
/// È più lunga dell'abitudine normale di proposito: all'inizio il launcher
/// non conosce ancora l'utente.
library;

import 'dart:math' as math;

import 'categories.dart';

/// Spinta in unità logaritmiche durante il plateau: ~e^8 ≈ 3000 volte,
/// abbastanza da tenere le preferite in cima finché i dati sono pochi.
const double initialBoost = 8;

const Duration boostPlateau = Duration(days: 21);
const Duration boostHalfLife = Duration(days: 21);

/// Sotto questa soglia la spinta si considera esaurita.
const double boostEpsilon = 0.05;

/// Fattore (0–1) della spinta dopo [age]: 1 durante il plateau, poi si
/// dimezza ogni [boostHalfLife].
double boostFactor(Duration age) {
  if (age <= boostPlateau) return 1;
  final over = (age - boostPlateau).inMinutes / boostHalfLife.inMinutes;
  return math.pow(0.5, over).toDouble();
}

class CategoryBoost {
  const CategoryBoost({
    required this.category,
    required this.created,
    this.weight = initialBoost,
  });

  final AppCategory category;
  final DateTime created;
  final double weight;

  /// Spinta attuale in unità logaritmiche.
  double at(DateTime now) => weight * boostFactor(now.difference(created));
}

/// Spinte attive a [now], per categoria.
Map<AppCategory, double> activeBoosts(
  Iterable<CategoryBoost> boosts,
  DateTime now,
) => {
  for (final b in boosts)
    if (b.at(now) > boostEpsilon) b.category: b.at(now),
};
