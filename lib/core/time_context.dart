/// Time context: time slots and day type
/// (spec-motore-contesto §6.4 and §7.1).
library;

enum Slot { wakeUp, morning, lunch, afternoon, evening, night }

enum DayType { workday, holiday }

/// The user's usual wake and sleep times, in minutes from midnight.
/// In v0.1 these are the defaults; in the future they will come from sleep
/// episodes (median of the last 14 days).
class DailyRhythm {
  const DailyRhythm({this.wakeMinute = 7 * 60, this.sleepMinute = 23 * 60});

  final int wakeMinute;
  final int sleepMinute;
}

const _lunchStart = 12 * 60;
const _lunchEnd = 14 * 60 + 30;
const _eveningStart = 19 * 60;

/// Time slot for the local time [t].
///
/// - wake-up: the first 2 hours after the usual wake time
/// - morning: until 12:00
/// - lunch: 12:00–14:30
/// - afternoon: until 19:00
/// - evening: from 19:00 until 1 hour before the usual sleep time
/// - night: the rest
Slot slotFor(DateTime t, {DailyRhythm rhythm = const DailyRhythm()}) {
  final m = t.hour * 60 + t.minute;
  final wake = rhythm.wakeMinute;
  final wakeEnd = wake + 120;
  // Night starts 1 hour before sleep; it may wrap past midnight.
  final nightStart = (rhythm.sleepMinute - 60) % (24 * 60);

  if (m >= wake && m < wakeEnd) return Slot.wakeUp;
  if (m >= wakeEnd && m < _lunchStart) return Slot.morning;
  if (m >= _lunchStart && m < _lunchEnd) return Slot.lunch;
  if (m >= _lunchEnd && m < _eveningStart) return Slot.afternoon;

  final eveningEnd = nightStart < _eveningStart ? 24 * 60 : nightStart;
  if (m >= _eveningStart && m < eveningEnd) return Slot.evening;
  return Slot.night;
}

/// Day type: workday, or holiday (Saturday, Sunday, public holidays).
DayType dayTypeFor(DateTime t, {String country = 'IT'}) {
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    return DayType.holiday;
  }
  return isPublicHoliday(t, country: country)
      ? DayType.holiday
      : DayType.workday;
}

/// National public holidays computed locally. In v0.1 only Italy.
bool isPublicHoliday(DateTime t, {String country = 'IT'}) {
  if (country != 'IT') return false;
  final d = DateTime(t.year, t.month, t.day);
  const fixed = <(int, int)>[
    (1, 1), // New Year's Day
    (1, 6), // Epiphany
    (4, 25), // Liberation Day
    (5, 1), // Labour Day
    (6, 2), // Republic Day
    (8, 15), // Ferragosto (Assumption)
    (11, 1), // All Saints' Day
    (12, 8), // Immaculate Conception
    (12, 25), // Christmas
    (12, 26), // St. Stephen's Day
  ];
  for (final (month, day) in fixed) {
    if (d.month == month && d.day == day) return true;
  }
  // St. Francis of Assisi, a national holiday since 2026.
  if (d.year >= 2026 && d.month == 10 && d.day == 4) return true;

  final easterMonday = easterSunday(d.year).add(const Duration(days: 1));
  return d == easterMonday;
}

/// Easter Sunday (Anonymous Gregorian algorithm, Meeus/Jones/Butcher).
DateTime easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// Discrete features of the current context used by the predictor
/// (spec-motore-contesto §7.1). In v0.2 `slot`, `daytype`, `network` and
/// `audio` are populated; `place` and `motion` will come with places (M1)
/// and are ignored while null.
class ContextFeatures {
  const ContextFeatures({
    required this.slot,
    required this.dayType,
    this.network,
    this.place,
    this.audio,
    this.motion,
  });

  factory ContextFeatures.at(
    DateTime t, {
    DailyRhythm rhythm = const DailyRhythm(),
    String? network,
    String? audio,
    String? motion,
    String? place,
  }) => ContextFeatures(
    slot: slotFor(t, rhythm: rhythm),
    dayType: dayTypeFor(t),
    network: network,
    audio: audio,
    motion: motion,
    place: place,
  );

  final Slot slot;
  final DayType dayType;

  /// `wifi`, `mobile` or `offline`.
  final String? network;
  final String? place;

  /// `speaker`, `headphones` or `bt`.
  final String? audio;
  final String? motion;

  /// Values by feature name, in the format stored in `launch_event`.
  Map<String, String?> toMap() => {
    'slot': slot.name,
    'daytype': dayType.name,
    'network': network,
    'place': place,
    'audio': audio,
    'motion': motion,
  };

  /// Key identifying the context: when it changes, the Collections may
  /// reorder (spec-viste-app §3.2).
  String get key =>
      '${slot.name}|${dayType.name}|${network ?? '-'}|${place ?? '-'}|'
      '${audio ?? '-'}|${motion ?? '-'}';
}
