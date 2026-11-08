import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/categories.dart';
import 'package:libreglide/core/places.dart';
import 'package:libreglide/core/space.dart';
import 'package:libreglide/core/space_profile.dart';

void main() {
  final now = DateTime(2026, 11, 6, 9);

  test('each moment has its own content', () {
    final morning = profileFor(SpaceKind.morning);
    final evening = profileFor(SpaceKind.evening);
    expect(morning.actions, isNot(evening.actions));
    expect(evening.weatherTomorrow, isTrue);
    expect(morning.weatherTomorrow, isFalse);
    // In the morning the agenda comes before the weather; in the evening
    // the screen-time summary moves to the top.
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

  test('a card hidden by the profile appears if you use it there', () {
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
    // The same taps don't count in the evening.
    expect(aff.affinity(SpaceCard.screenTime, now, {'slot': 'evening'}), 0);
  });

  test('usage moves a card up', () {
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

  test('user choices win', () {
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

  test('old taps weigh less', () {
    final aff = CardAffinity();
    aff.add(SpaceCard.media, now.subtract(const Duration(days: 42)), {
      'audio': 'headphones',
    });
    final a = aff.affinity(SpaceCard.media, now, {'audio': 'headphones'});
    expect(a, closeTo(0.25, 0.01));
  });

  test('the work Space is weighed by work or school', () {
    final work = profileFor(SpaceKind.work, workKind: WorkKind.work);
    final school = profileFor(SpaceKind.work, workKind: WorkKind.school);
    final unknown = profileFor(SpaceKind.work);
    expect(work.actions, contains(QuickAction.email));
    expect(work.category, AppCategory.work);
    expect(school.actions, isNot(contains(QuickAction.email)));
    expect(school.category, AppCategory.education);
    expect(school.hidden, containsAll([SpaceCard.media, SpaceCard.weather]));
    expect(unknown.category, AppCategory.work);
  });
}
