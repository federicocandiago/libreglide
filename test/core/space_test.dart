import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/places.dart';
import 'package:libreglide/core/space.dart';
import 'package:libreglide/core/time_context.dart';

void main() {
  test('priority: car, headphones, travel, work, home, time', () {
    expect(
      selectSpace(slot: Slot.morning, driving: true, audio: 'bt'),
      SpaceKind.moving,
    );
    expect(
      selectSpace(slot: Slot.morning, audio: 'headphones', travelling: true),
      SpaceKind.listening,
    );
    expect(
      selectSpace(slot: Slot.morning, travelling: true, place: PlaceRole.work),
      SpaceKind.travel,
    );
    expect(
      selectSpace(slot: Slot.morning, place: PlaceRole.work),
      SpaceKind.work,
    );
    expect(
      selectSpace(slot: Slot.afternoon, place: PlaceRole.home),
      SpaceKind.home,
    );
    expect(selectSpace(slot: Slot.lunch), SpaceKind.lunch);
  });

  test('at home: wake-up and evening stay time-based Spaces', () {
    expect(
      selectSpace(slot: Slot.wakeUp, place: PlaceRole.home),
      SpaceKind.wakeUp,
    );
    expect(
      selectSpace(slot: Slot.evening, place: PlaceRole.home),
      SpaceKind.evening,
    );
  });

  test('Spaces and time slots', () {
    for (final s in Slot.values) {
      expect(SpaceKind.ofSlot(s).slot, s);
    }
    expect(SpaceKind.home.contextual, isTrue);
    expect(SpaceKind.night.contextual, isFalse);
  });

  test('exercise wins over headphones, night out comes after travel', () {
    expect(
      selectSpace(slot: Slot.evening, exercising: true, audio: 'bt'),
      SpaceKind.exercise,
    );
    expect(
      selectSpace(slot: Slot.evening, exercising: true, driving: true),
      SpaceKind.moving,
    );
    expect(
      selectSpace(slot: Slot.night, nightOut: true, travelling: true),
      SpaceKind.travel,
    );
    expect(
      selectSpace(slot: Slot.night, nightOut: true, place: PlaceRole.none),
      SpaceKind.nightOut,
    );
  });

  group('night out', () {
    bool out(
      DateTime now, {
      Slot slot = Slot.evening,
      PlaceRole? place = PlaceRole.none,
      String? network = 'mobile',
      bool homeKnown = true,
    }) => isNightOut(
      now: now,
      slot: slot,
      place: place,
      network: network,
      homeKnown: homeKnown,
    );

    // 2026-11-06 is a Friday.
    test('Friday and Saturday evening: any place but home and work', () {
      expect(out(DateTime(2026, 11, 6, 19, 30)), isTrue);
      expect(out(DateTime(2026, 11, 7, 20), place: PlaceRole.frequent), isTrue);
      expect(out(DateTime(2026, 11, 7, 20), place: PlaceRole.home), isFalse);
      expect(out(DateTime(2026, 11, 7, 20), place: PlaceRole.work), isFalse);
    });

    test('after midnight it is still the night before', () {
      // Saturday 01:30 = Friday night.
      expect(out(DateTime(2026, 11, 7, 1, 30), slot: Slot.night), isTrue);
      // Tuesday 01:30 = Monday night, occasional place.
      expect(out(DateTime(2026, 11, 10, 1, 30), slot: Slot.night), isTrue);
    });

    test('Sunday from 20:30', () {
      expect(out(DateTime(2026, 11, 8, 20)), isFalse);
      expect(out(DateTime(2026, 11, 8, 20, 45)), isTrue);
    });

    test('weekdays: from 21:00 and only at an occasional place', () {
      expect(out(DateTime(2026, 11, 10, 20, 30)), isFalse);
      expect(out(DateTime(2026, 11, 10, 21, 15)), isTrue);
      expect(
        out(DateTime(2026, 11, 10, 21, 15), place: PlaceRole.frequent),
        isFalse,
      );
    });

    test('the eve of a public holiday counts as a weekend', () {
      // Monday 7 December 2026, the day before the Immaculate Conception.
      expect(
        out(DateTime(2026, 12, 7, 19, 30), place: PlaceRole.frequent),
        isTrue,
      );
    });

    test('never before home is known: home would look like elsewhere', () {
      expect(
        out(
          DateTime(2026, 11, 7, 22),
          place: PlaceRole.frequent,
          homeKnown: false,
        ),
        isFalse,
      );
    });

    test('never on Wi-Fi, without a located place or by day', () {
      expect(out(DateTime(2026, 11, 7, 22), network: 'wifi'), isFalse);
      expect(out(DateTime(2026, 11, 7, 22), place: null), isFalse);
      expect(out(DateTime(2026, 11, 7, 16), slot: Slot.afternoon), isFalse);
    });
  });
}
