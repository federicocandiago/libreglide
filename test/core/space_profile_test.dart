import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/space.dart';
import 'package:libreglide/core/space_profile.dart';

void main() {
  final now = DateTime(2026, 11, 6, 9);

  test('ogni momento ha il suo contenuto', () {
    final morning = profileFor(SpaceKind.morning);
    final evening = profileFor(SpaceKind.evening);
    expect(morning.actions, isNot(evening.actions));
    expect(evening.weatherTomorrow, isTrue);
    expect(morning.weatherTomorrow, isFalse);
    // Di mattina l'agenda viene prima del meteo; di sera il riepilogo
    // del tempo di utilizzo sale in cima.
    final m = arrangeCards(
      profile: morning,
      available: [SpaceCard.weather, SpaceCard.agenda, SpaceCard.apps],
    );
    expect(m.first, SpaceCard.agenda);
    final e = arrangeCards(
      profile: evening,
      available: [SpaceCard.apps, SpaceCard.weather, SpaceCard.screenTime],
    );
    expect(e.first, SpaceCard.screenTime);
  });

  test('una card nascosta dal profilo compare se la usi lì', () {
    final profile = profileFor(SpaceKind.morning);
    final aff = CardAffinity();
    expect(
      arrangeCards(profile: profile, available: [SpaceCard.screenTime]),
      isEmpty,
    );
    for (var i = 0; i < 4; i++) {
      aff.add(SpaceCard.screenTime, now.subtract(Duration(days: i)), {
        'slot': 'morning',
      });
    }
    final a = aff.affinity(SpaceCard.screenTime, now, {'slot': 'morning'});
    expect(a, greaterThan(promoteAt));
    expect(
      arrangeCards(
        profile: profile,
        available: [SpaceCard.screenTime],
        affinity: {SpaceCard.screenTime: a},
      ),
      [SpaceCard.screenTime],
    );
    // Gli stessi tocchi non contano di sera.
    expect(aff.affinity(SpaceCard.screenTime, now, {'slot': 'evening'}), 0);
  });

  test("l'uso fa salire una card", () {
    final profile = profileFor(SpaceKind.afternoon);
    final base = arrangeCards(
      profile: profile,
      available: [SpaceCard.media, SpaceCard.weather],
    );
    expect(base.first, SpaceCard.media);
    final used = arrangeCards(
      profile: profile,
      available: [SpaceCard.media, SpaceCard.weather],
      affinity: {SpaceCard.weather: 10},
    );
    expect(used.first, SpaceCard.weather);
  });

  test('le scelte dell\'utente vincono', () {
    final profile = profileFor(SpaceKind.morning);
    final cards = arrangeCards(
      profile: profile,
      available: [SpaceCard.agenda, SpaceCard.weather, SpaceCard.screenTime],
      rules: {
        SpaceCard.agenda: CardRule.hide,
        SpaceCard.screenTime: CardRule.show,
      },
    );
    expect(cards, [SpaceCard.screenTime, SpaceCard.weather]);
  });

  test('i tocchi vecchi pesano meno', () {
    final aff = CardAffinity();
    aff.add(SpaceCard.media, now.subtract(const Duration(days: 42)), {
      'audio': 'headphones',
    });
    final a = aff.affinity(SpaceCard.media, now, {'audio': 'headphones'});
    expect(a, closeTo(0.25, 0.01));
  });
}
