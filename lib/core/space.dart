/// Scelta dello Space (spec-motore-contesto §8.2): prima il contesto
/// (auto, cuffie, viaggio, lavoro, casa), poi l'ora del giorno.
library;

import 'places.dart';
import 'time_context.dart';

enum SpaceKind {
  // Space di contesto.
  moving,
  listening,
  travel,
  work,
  home,
  // Space dell'ora del giorno.
  wakeUp,
  morning,
  lunch,
  afternoon,
  evening,
  night;

  /// Lo Space che corrisponde a una fascia oraria.
  static SpaceKind ofSlot(Slot s) => switch (s) {
    Slot.wakeUp => wakeUp,
    Slot.morning => morning,
    Slot.lunch => lunch,
    Slot.afternoon => afternoon,
    Slot.evening => evening,
    Slot.night => night,
  };

  /// La fascia oraria, per gli Space dell'ora; null per quelli di contesto.
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

/// Regole in ordine di priorità: la prima vera vince.
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
    // A casa la mattina presto resta il Risveglio, la sera la Sera/Notte:
    // sono le routine di casa più riconoscibili.
    if (slot == Slot.wakeUp || slot == Slot.evening || slot == Slot.night) {
      return SpaceKind.ofSlot(slot);
    }
    return SpaceKind.home;
  }
  return SpaceKind.ofSlot(slot);
}
