/// Contesto temporale: fasce orarie e tipo di giorno
/// (spec-motore-contesto §6.4 e §7.1).
library;

enum Slot { wakeUp, morning, lunch, afternoon, evening, night }

enum DayType { workday, holiday }

/// Orari abituali dell'utente in minuti dalla mezzanotte.
/// In v0.1 sono i valori predefiniti; in futuro arriveranno dagli
/// episodi di sonno (mediana degli ultimi 14 giorni).
class DailyRhythm {
  const DailyRhythm({this.wakeMinute = 7 * 60, this.sleepMinute = 23 * 60});

  final int wakeMinute;
  final int sleepMinute;
}

const _lunchStart = 12 * 60;
const _lunchEnd = 14 * 60 + 30;
const _eveningStart = 19 * 60;

/// Fascia oraria per l'ora locale [t].
///
/// - risveglio: le prime 2 ore dopo il risveglio abituale
/// - mattina: fino alle 12
/// - pranzo: 12:00–14:30
/// - pomeriggio: fino alle 19
/// - sera: dalle 19 fino a 1 ora prima del sonno abituale
/// - notte: il resto
Slot slotFor(DateTime t, {DailyRhythm rhythm = const DailyRhythm()}) {
  final m = t.hour * 60 + t.minute;
  final wake = rhythm.wakeMinute;
  final wakeEnd = wake + 120;
  // La notte inizia 1 ora prima del sonno; può scavalcare la mezzanotte.
  final nightStart = (rhythm.sleepMinute - 60) % (24 * 60);

  if (m >= wake && m < wakeEnd) return Slot.wakeUp;
  if (m >= wakeEnd && m < _lunchStart) return Slot.morning;
  if (m >= _lunchStart && m < _lunchEnd) return Slot.lunch;
  if (m >= _lunchEnd && m < _eveningStart) return Slot.afternoon;

  final eveningEnd = nightStart < _eveningStart ? 24 * 60 : nightStart;
  if (m >= _eveningStart && m < eveningEnd) return Slot.evening;
  return Slot.night;
}

/// Tipo di giorno: feriale, oppure festivo (sabato, domenica, festività).
DayType dayTypeFor(DateTime t, {String country = 'IT'}) {
  if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
    return DayType.holiday;
  }
  return isPublicHoliday(t, country: country)
      ? DayType.holiday
      : DayType.workday;
}

/// Festività nazionali calcolate in locale. In v0.1 solo l'Italia.
bool isPublicHoliday(DateTime t, {String country = 'IT'}) {
  if (country != 'IT') return false;
  final d = DateTime(t.year, t.month, t.day);
  const fixed = <(int, int)>[
    (1, 1), // Capodanno
    (1, 6), // Epifania
    (4, 25), // Liberazione
    (5, 1), // Festa dei lavoratori
    (6, 2), // Festa della Repubblica
    (8, 15), // Ferragosto
    (11, 1), // Ognissanti
    (12, 8), // Immacolata
    (12, 25), // Natale
    (12, 26), // Santo Stefano
  ];
  for (final (month, day) in fixed) {
    if (d.month == month && d.day == day) return true;
  }
  // San Francesco d'Assisi, festività nazionale dal 2026.
  if (d.year >= 2026 && d.month == 10 && d.day == 4) return true;

  final easterMonday = easterSunday(d.year).add(const Duration(days: 1));
  return d == easterMonday;
}

/// Domenica di Pasqua (algoritmo gregoriano anonimo, Meeus/Jones/Butcher).
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

/// Feature discrete del contesto corrente usate dal predittore
/// (spec-motore-contesto §7.1). In v0.2 sono valorizzate `slot`, `daytype`,
/// `network` e `audio`; `place` e `motion` arriveranno con i luoghi (M1)
/// e finché sono null vengono ignorate.
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

  /// `wifi`, `mobile` o `offline`.
  final String? network;
  final String? place;

  /// `speaker`, `headphones` o `bt`.
  final String? audio;
  final String? motion;

  /// Valori per nome di feature, nel formato salvato in `launch_event`.
  Map<String, String?> toMap() => {
    'slot': slot.name,
    'daytype': dayType.name,
    'network': network,
    'place': place,
    'audio': audio,
    'motion': motion,
  };

  /// Chiave che identifica il contesto: quando cambia, le Collections
  /// possono riordinarsi (spec-viste-app §3.2).
  String get key =>
      '${slot.name}|${dayType.name}|${network ?? '-'}|${place ?? '-'}|'
      '${audio ?? '-'}|${motion ?? '-'}';
}
