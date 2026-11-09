/// Space selection (spec-motore-contesto §8.2): context first (car,
/// exercise, headphones, travel, night out, work, home), then the time of
/// day.
library;

import 'places.dart';
import 'time_context.dart';

enum SpaceKind {
  // Context Spaces.
  moving,
  exercise,
  listening,
  travel,
  nightOut,
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
  bool exercising = false,
  String? audio,
  bool travelling = false,
  bool nightOut = false,
}) {
  if (driving) return SpaceKind.moving;
  // Above headphones: whoever runs usually has them on.
  if (exercising) return SpaceKind.exercise;
  if (audio == 'headphones' || audio == 'bt') return SpaceKind.listening;
  if (travelling) return SpaceKind.travel;
  if (nightOut) return SpaceKind.nightOut;
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

/// Night out: an evening or night away from home and work, not on Wi-Fi,
/// at a place the phone has located ([place] not null). Only once home has
/// been recognized ([homeKnown]): before that, home itself would look like
/// "a place other than home".
///
/// - Friday, Saturday and the eve of a public holiday: any place other than
///   home and work, from the start of the evening.
/// - Sunday: the same, from 20:30.
/// - Monday to Thursday: from 21:00, and only at an occasional place (not
///   a frequent one, like the weekly gym).
///
/// Hours after midnight belong to the evening before (Saturday 01:00 is
/// still Friday night).
bool isNightOut({
  required DateTime now,
  required Slot slot,
  required PlaceRole? place,
  required String? network,
  required bool homeKnown,
  String country = 'IT',
}) {
  if (!homeKnown) return false;
  if (slot != Slot.evening && slot != Slot.night) return false;
  if (place == null || place == PlaceRole.home || place == PlaceRole.work) {
    return false;
  }
  if (network == 'wifi') return false;
  final afterMidnight = now.hour < 6;
  final evening = afterMidnight ? now.subtract(const Duration(hours: 6)) : now;
  final minutes = afterMidnight ? 24 * 60 : now.hour * 60 + now.minute;
  final tomorrow = DateTime(evening.year, evening.month, evening.day + 1);
  final eve =
      evening.weekday == DateTime.friday ||
      evening.weekday == DateTime.saturday ||
      isPublicHoliday(tomorrow, country: country);
  if (eve) return true;
  if (evening.weekday == DateTime.sunday) return minutes >= 20 * 60 + 30;
  return minutes >= 21 * 60 && place == PlaceRole.none;
}

/// What the Space page is built from: where the phone is and what is
/// happening. The automatic Space uses the real signals; a Space picked by
/// hand stands for its own situation, so the whole page follows the choice
/// (cards, suggested apps), not just the header.
class SpaceSituation {
  const SpaceSituation({
    required this.slot,
    this.place,
    this.driving = false,
    this.exercising = false,
    this.listening = false,
    this.travelling = false,
    this.nightOut = false,
  });

  final Slot slot;
  final PlaceRole? place;
  final bool driving;
  final bool exercising;
  final bool listening;
  final bool travelling;
  final bool nightOut;

  bool get atHomeOrWork => place == PlaceRole.home || place == PlaceRole.work;

  /// The situation [kind] stands for, starting from this (real) one.
  ///
  /// A picked Space is that situation alone: the other activities are off.
  /// Places set the place; time-of-day Spaces set the time slot and keep the
  /// real place; travel and night out mean being away from home and work.
  SpaceSituation picked(SpaceKind kind) => switch (kind) {
    SpaceKind.home || SpaceKind.work => SpaceSituation(
      slot: slot,
      place: kind == SpaceKind.home ? PlaceRole.home : PlaceRole.work,
    ),
    SpaceKind.moving => SpaceSituation(slot: slot, place: place, driving: true),
    SpaceKind.exercise => SpaceSituation(
      slot: slot,
      place: place,
      exercising: true,
    ),
    SpaceKind.listening => SpaceSituation(
      slot: slot,
      place: place,
      listening: true,
    ),
    SpaceKind.travel => SpaceSituation(
      slot: slot,
      place: PlaceRole.none,
      travelling: true,
    ),
    SpaceKind.nightOut => SpaceSituation(
      slot: slot,
      place: PlaceRole.none,
      nightOut: true,
    ),
    _ => SpaceSituation(slot: kind.slot!, place: place),
  };

  /// The predictor's context features, adjusted to this situation.
  /// [real] are the features read from the system; network, weekday and the
  /// like stay as they are.
  Map<String, String?> features(Map<String, String?> real) => {
    ...real,
    'slot': slot.name,
    'place': travelling
        ? 'travel'
        : switch (place) {
            PlaceRole.home => 'home',
            PlaceRole.work => 'work',
            PlaceRole.none => 'other',
            // A frequent place keeps its own id (frequent:ID).
            PlaceRole.frequent => real['place'],
            null => real['place'],
          },
    'motion': driving
        ? 'driving'
        : exercising
        ? 'exercise'
        : null,
    'audio': listening
        ? 'headphones'
        : (real['audio'] == 'headphones' || real['audio'] == 'bt')
        ? null
        : real['audio'],
  };
}
