/// Initial boost for the favorite collections picked during onboarding.
///
/// For the first weeks the favorites stay on top (the "plateau"), then the
/// boost halves at regular intervals and gives way to real usage. It is
/// deliberately longer than the normal habit decay: at first the launcher
/// doesn't know the user yet.
library;

import 'dart:math' as math;

import 'categories.dart';

/// Boost in log units during the plateau: ~e^8 ≈ 3000x, enough to keep the
/// favorites on top while there is little data.
const double initialBoost = 8;

const Duration boostPlateau = Duration(days: 21);
const Duration boostHalfLife = Duration(days: 21);

/// Below this threshold the boost is considered spent.
const double boostEpsilon = 0.05;

/// Boost factor (0–1) after [age]: 1 during the plateau, then it halves
/// every [boostHalfLife].
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

  /// Current boost in log units.
  double at(DateTime now) => weight * boostFactor(now.difference(created));
}

/// Boosts active at [now], per category.
Map<AppCategory, double> activeBoosts(
  Iterable<CategoryBoost> boosts,
  DateTime now,
) => {
  for (final b in boosts)
    if (b.at(now) > boostEpsilon) b.category: b.at(now),
};
