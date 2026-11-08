/// What each Space shows: quick actions, featured cards, a row of apps from
/// one category. This is the baseline; usage (cards tapped in a context) and
/// the user's choices ("Hide here", "Always show here") adapt it (see
/// [CardAffinity] and [arrangeCards]).
library;

import 'dart:math' as math;

import 'categories.dart';
import 'places.dart';
import 'space.dart';

/// Glide cards of the Space (Android widgets are not part of this).
enum SpaceCard {
  car,
  parking,
  evening,
  alarm,
  media,
  travel,
  nextPlace,
  agenda,
  weather,
  apps,
  category,
  screenTime,
  placesInvite,
}

/// Quick actions of the card at the top of the Space.
enum QuickAction {
  alarm,
  alarmTomorrow,
  dnd,
  newEvent,
  email,
  maps,
  toHome,
  toWork,
  timer,
  food,
}

class SpaceProfile {
  const SpaceProfile({
    required this.actions,
    this.category,
    this.priority = const {},
    this.hidden = const {},
    this.agendaWhenEmpty = false,
    this.weatherTomorrow = false,
  });

  final List<QuickAction> actions;

  /// Row of apps from this category (null = none).
  final AppCategory? category;

  /// Base priority in this Space (lower = higher up); cards not listed use
  /// [defaultCardPriority].
  final Map<SpaceCard, int> priority;

  /// Cards this Space doesn't show unless usage or the user asks for them.
  final Set<SpaceCard> hidden;

  /// The empty agenda stays visible ("free day").
  final bool agendaWhenEmpty;

  /// Weather shows tomorrow instead of the next hours.
  final bool weatherTomorrow;
}

const Map<SpaceCard, int> defaultCardPriority = {
  SpaceCard.car: 0,
  SpaceCard.parking: 1,
  SpaceCard.evening: 5,
  SpaceCard.apps: 20,
  SpaceCard.nextPlace: 25,
  SpaceCard.category: 28,
  SpaceCard.agenda: 30,
  SpaceCard.media: 35,
  SpaceCard.travel: 40,
  SpaceCard.weather: 45,
  SpaceCard.alarm: 60,
  SpaceCard.screenTime: 75,
  SpaceCard.placesInvite: 80,
};

/// [workKind] weighs the work Space: more tools at work, fewer at school
/// (null = not known yet, the work profile).
SpaceProfile profileFor(SpaceKind kind, {WorkKind? workKind}) => switch (kind) {
  SpaceKind.work when workKind == WorkKind.school => const SpaceProfile(
    // Silent in class, a timer for study; the timetable on top and little
    // else: no email, commute, music or weather in the way.
    actions: [QuickAction.dnd, QuickAction.timer],
    category: AppCategory.education,
    priority: {SpaceCard.agenda: 10},
    hidden: {
      SpaceCard.screenTime,
      SpaceCard.nextPlace,
      SpaceCard.media,
      SpaceCard.weather,
    },
    agendaWhenEmpty: true,
  ),
  SpaceKind.wakeUp => const SpaceProfile(
    actions: [QuickAction.alarm, QuickAction.dnd],
    category: AppCategory.news,
    priority: {SpaceCard.weather: 10, SpaceCard.agenda: 12},
    hidden: {SpaceCard.screenTime},
    agendaWhenEmpty: true,
  ),
  SpaceKind.morning => const SpaceProfile(
    actions: [QuickAction.newEvent, QuickAction.maps],
    category: AppCategory.productivity,
    priority: {
      SpaceCard.agenda: 10,
      SpaceCard.nextPlace: 11,
      SpaceCard.weather: 15,
    },
    hidden: {SpaceCard.screenTime},
    agendaWhenEmpty: true,
  ),
  SpaceKind.lunch => const SpaceProfile(
    actions: [QuickAction.timer, QuickAction.food],
    category: AppCategory.food,
    priority: {SpaceCard.category: 12, SpaceCard.agenda: 24},
    hidden: {SpaceCard.screenTime},
  ),
  SpaceKind.afternoon => const SpaceProfile(
    actions: [QuickAction.newEvent, QuickAction.timer],
    category: AppCategory.shopping,
    priority: {SpaceCard.agenda: 12, SpaceCard.nextPlace: 13},
    hidden: {SpaceCard.screenTime},
  ),
  SpaceKind.evening => const SpaceProfile(
    actions: [QuickAction.alarmTomorrow, QuickAction.dnd],
    category: AppCategory.video,
    priority: {
      SpaceCard.screenTime: 12,
      SpaceCard.agenda: 15,
      SpaceCard.weather: 16,
      SpaceCard.category: 22,
    },
    weatherTomorrow: true,
  ),
  SpaceKind.night => const SpaceProfile(
    actions: [QuickAction.alarmTomorrow, QuickAction.dnd],
    priority: {SpaceCard.weather: 15, SpaceCard.agenda: 16},
    hidden: {SpaceCard.screenTime},
    weatherTomorrow: true,
  ),
  SpaceKind.work => const SpaceProfile(
    actions: [QuickAction.newEvent, QuickAction.email],
    category: AppCategory.work,
    priority: {SpaceCard.agenda: 10, SpaceCard.nextPlace: 11},
    hidden: {SpaceCard.screenTime},
  ),
  SpaceKind.home => const SpaceProfile(
    actions: [QuickAction.alarm, QuickAction.dnd],
    category: AppCategory.video,
  ),
  SpaceKind.moving => const SpaceProfile(
    actions: [QuickAction.toHome, QuickAction.toWork],
    category: AppCategory.maps,
    priority: {SpaceCard.nextPlace: 8},
    hidden: {SpaceCard.screenTime},
  ),
  SpaceKind.travel => const SpaceProfile(
    actions: [QuickAction.toHome, QuickAction.maps],
    category: AppCategory.maps,
    priority: {SpaceCard.travel: 6, SpaceCard.nextPlace: 8},
    hidden: {SpaceCard.screenTime},
  ),
  SpaceKind.nightOut => const SpaceProfile(
    actions: [QuickAction.toHome, QuickAction.maps],
    category: AppCategory.social,
    priority: {SpaceCard.weather: 30},
    hidden: {SpaceCard.screenTime, SpaceCard.agenda},
  ),
  SpaceKind.exercise => const SpaceProfile(
    actions: [QuickAction.timer, QuickAction.dnd],
    category: AppCategory.health,
    priority: {SpaceCard.media: 6, SpaceCard.weather: 10},
    hidden: {SpaceCard.screenTime, SpaceCard.agenda, SpaceCard.nextPlace},
  ),
  SpaceKind.listening => const SpaceProfile(
    actions: [QuickAction.alarm, QuickAction.dnd],
    category: AppCategory.music,
    priority: {SpaceCard.media: 6},
  ),
};

/// The user's choice for a card in a Space.
enum CardRule { show, hide }

/// Card interactions (taps) with their context. A card's affinity in a
/// context is the number of taps in that time slot or place (or with
/// headphones, in the car), weighted with a decay: recent actions count
/// more.
class CardAffinity {
  CardAffinity({this.halfLife = const Duration(days: 21)});

  final Duration halfLife;
  final List<(SpaceCard, DateTime, Map<String, String?>, int)> _events = [];

  /// Signals describing the context of a tap.
  static const _features = ['slot', 'place', 'audio', 'motion'];

  /// Values too generic to tell anything.
  static const _ignored = {'other', 'speaker'};

  /// Adds a tap ([count] taps for a compacted row).
  void add(
    SpaceCard card,
    DateTime t,
    Map<String, String?> features, {
    int count = 1,
  }) => _events.add((card, t, features, count));

  void clear() => _events.clear();

  int get length => _events.length;

  /// Affinity of [card] in context [ctx] right now.
  double affinity(SpaceCard card, DateTime now, Map<String, String?> ctx) {
    var best = 0.0;
    for (final f in _features) {
      final v = ctx[f];
      if (v == null || _ignored.contains(v)) continue;
      var sum = 0.0;
      for (final (c, t, features, count) in _events) {
        if (c != card || features[f] != v) continue;
        final age = now.difference(t).inMinutes / halfLife.inMinutes;
        sum += count * math.pow(0.5, age.clamp(0, 60)).toDouble();
      }
      if (sum > best) best = sum;
    }
    return best;
  }
}

/// Recent taps in the context above which a card hidden by the profile
/// shows up anyway.
const double promoteAt = 3;

/// Orders the available cards for this Space: profile priority, usage
/// boost, user choices. [available] are the cards that currently have
/// something to show.
List<SpaceCard> arrangeCards({
  required SpaceProfile profile,
  required Iterable<SpaceCard> available,
  Map<SpaceCard, double> affinity = const {},
  Map<SpaceCard, CardRule> rules = const {},
}) {
  final scored = <(SpaceCard, double, int)>[];
  for (final (i, card) in available.indexed) {
    final rule = rules[card];
    if (rule == CardRule.hide) continue;
    final a = affinity[card] ?? 0;
    final hiddenByProfile = profile.hidden.contains(card);
    if (hiddenByProfile && rule != CardRule.show && a < promoteAt) continue;
    var p = (profile.priority[card] ?? defaultCardPriority[card] ?? 50)
        .toDouble();
    // The more you use it here, the higher it goes (up to 18 priority steps).
    p -= math.min(18, a * 3);
    // "Always show here": near the top, after urgent cards (car, parking).
    if (rule == CardRule.show) p = math.min(p, 4);
    scored.add((card, p, i));
  }
  scored.sort((a, b) => a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$3 - b.$3);
  return [for (final (c, _, _) in scored) c];
}
