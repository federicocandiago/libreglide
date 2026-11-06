/// Cosa mostra ogni Space: azioni rapide, card in primo piano, una riga di
/// app di una categoria. È la base; l'uso (le card toccate in un contesto)
/// e le scelte dell'utente ("Nascondi qui", "Mostra sempre qui") la
/// adattano (vedi [CardAffinity] e [arrangeCards]).
library;

import 'dart:math' as math;

import 'categories.dart';
import 'space.dart';

/// Card di Glide dello Space (i widget Android non ne fanno parte).
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

/// Azioni rapide della card in cima allo Space.
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

  /// Riga di app di questa categoria (null = nessuna).
  final AppCategory? category;

  /// Priorità di base in questo Space (più bassa = più in alto); le card
  /// assenti usano [defaultCardPriority].
  final Map<SpaceCard, int> priority;

  /// Card che questo Space non mostra, se l'uso o l'utente non le chiedono.
  final Set<SpaceCard> hidden;

  /// L'agenda vuota resta visibile ("giornata libera").
  final bool agendaWhenEmpty;

  /// Il meteo mostra domani invece delle prossime ore.
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

SpaceProfile profileFor(SpaceKind kind) => switch (kind) {
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
  SpaceKind.listening => const SpaceProfile(
    actions: [QuickAction.alarm, QuickAction.dnd],
    category: AppCategory.music,
    priority: {SpaceCard.media: 6},
  ),
};

/// Scelta dell'utente per una card in uno Space.
enum CardRule { show, hide }

/// Interazioni con le card (tocchi), con il loro contesto. L'affinità di
/// una card in un contesto è il numero di tocchi in quella fascia oraria o
/// in quel luogo (o con le cuffie, in auto), pesati con un decadimento:
/// conta di più ciò che hai fatto di recente.
class CardAffinity {
  CardAffinity({this.halfLife = const Duration(days: 21)});

  final Duration halfLife;
  final List<(SpaceCard, DateTime, Map<String, String?>)> _events = [];

  /// Segnali che descrivono il contesto di un tocco.
  static const _features = ['slot', 'place', 'audio', 'motion'];

  /// Valori troppo generici per dire qualcosa.
  static const _ignored = {'other', 'speaker'};

  void add(SpaceCard card, DateTime t, Map<String, String?> features) =>
      _events.add((card, t, features));

  void clear() => _events.clear();

  int get length => _events.length;

  /// Affinità di [card] nel contesto [ctx] adesso.
  double affinity(SpaceCard card, DateTime now, Map<String, String?> ctx) {
    var best = 0.0;
    for (final f in _features) {
      final v = ctx[f];
      if (v == null || _ignored.contains(v)) continue;
      var sum = 0.0;
      for (final (c, t, features) in _events) {
        if (c != card || features[f] != v) continue;
        final age = now.difference(t).inMinutes / halfLife.inMinutes;
        sum += math.pow(0.5, age.clamp(0, 60)).toDouble();
      }
      if (sum > best) best = sum;
    }
    return best;
  }
}

/// Tocchi recenti nel contesto oltre cui una card nascosta dal profilo
/// compare comunque.
const double promoteAt = 3;

/// Ordina le card disponibili per questo Space: priorità del profilo,
/// spinta dell'uso, scelte dell'utente. [available] sono le card che adesso
/// hanno qualcosa da mostrare.
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
    // Più la usi qui, più sale (fino a 18 posizioni di priorità).
    p -= math.min(18, a * 3);
    // "Mostra sempre qui": in alto, dopo le card urgenti (auto, parcheggio).
    if (rule == CardRule.show) p = math.min(p, 4);
    scored.add((card, p, i));
  }
  scored.sort((a, b) => a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$3 - b.$3);
  return [for (final (c, _, _) in scored) c];
}
