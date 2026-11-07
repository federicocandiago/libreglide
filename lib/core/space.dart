/// Space selection (spec-motore-contesto §8.2): context first (car,
/// headphones, travel, work, home), then the time of day.
library;

import 'places.dart';
import 'time_context.dart';

enum SpaceKind {
  // Context Spaces.
  moving,
  listening,
  travel,
  work,
  home,
  // Time-of-day Spaces.
  wakeUp,
  morning,
  lunch,
  afternoon,
  evening,
  night;

  /// The Space matching a time slot.
  static SpaceKind ofSlot(Slot s) => switch (s) {
    Slot.wakeUp => wakeUp,
    Slot.morning => morning,
    Slot.lunch => lunch,
    Slot.afternoon => afternoon,
    Slot.evening => evening,
    Slot.night => night,
  };

  /// The time slot for time-of-day Spaces; null for context Spaces.
  Slot? get slot => switch (this) {
    wakeUp => Slot.wakeUp,
    morning => Slot.morning,
    lunch => Slot.lunch,
    afternoon => Slot.afternoon,
    evening => Slot.evening,
    night => Slot.night,
    _ => null,
  };

  bool get contextual => slot == null;
}

/// Rules in priority order: the first one that holds wins.
SpaceKind selectSpace({
  required Slot slot,
  PlaceRole? place,
  bool driving = false,
  String? audio,
  bool travelling = false,
}) {
  if (driving) return SpaceKind.moving;
  if (audio == 'headphones' || audio == 'bt') return SpaceKind.listening;
  if (travelling) return SpaceKind.travel;
  if (place == PlaceRole.work) return SpaceKind.work;
  if (place == PlaceRole.home) {
    // At home, early morning stays Wake-up and the evening stays
    // Evening/Night: they are the most recognizable home routines.
    if (slot == Slot.wakeUp || slot == Slot.evening || slot == Slot.night) {
      return SpaceKind.ofSlot(slot);
    }
    return SpaceKind.home;
  }
  return SpaceKind.ofSlot(slot);
}
