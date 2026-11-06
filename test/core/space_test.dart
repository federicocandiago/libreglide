import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/places.dart';
import 'package:libreglide/core/space.dart';
import 'package:libreglide/core/time_context.dart';

void main() {
  test('priorità: auto, cuffie, viaggio, lavoro, casa, ora', () {
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

  test('a casa: risveglio e sera restano Space dell\'ora', () {
    expect(
      selectSpace(slot: Slot.wakeUp, place: PlaceRole.home),
      SpaceKind.wakeUp,
    );
    expect(
      selectSpace(slot: Slot.evening, place: PlaceRole.home),
      SpaceKind.evening,
    );
  });

  test('Space e fasce orarie', () {
    for (final s in Slot.values) {
      expect(SpaceKind.ofSlot(s).slot, s);
    }
    expect(SpaceKind.home.contextual, isTrue);
    expect(SpaceKind.night.contextual, isFalse);
  });
}
