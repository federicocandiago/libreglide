/// Momento della giornata per lo sfondo contestuale e parole chiave per
/// Unsplash, scelti in modo deterministico (stesso contesto → stessa
/// ricerca).
///
/// Priorità: festività → viaggio → meteo notevole → musica → fascia oraria +
/// stagione.
/// Le parole chiave sono in inglese perché su Unsplash rendono meglio.
library;

import 'time_context.dart';
import 'weather.dart';

enum MomentKind { holiday, travel, weather, music, daily }

class WallpaperMoment {
  const WallpaperMoment(this.kind, this.id, this.query);

  final MomentKind kind;

  /// Identificatore stabile del momento (es. `holiday:christmas`,
  /// `daily:evening:autumn`).
  final String id;

  /// Ricerca per Unsplash.
  final String query;

  @override
  String toString() => '$id → "$query"';
}

enum Season { winter, spring, summer, autumn }

/// Stagione meteorologica (emisfero nord).
Season seasonOf(DateTime t) => switch (t.month) {
  12 || 1 || 2 => Season.winter,
  3 || 4 || 5 => Season.spring,
  6 || 7 || 8 => Season.summer,
  _ => Season.autumn,
};

const _seasonWords = {
  Season.winter: 'winter',
  Season.spring: 'spring flowers',
  Season.summer: 'summer',
  Season.autumn: 'autumn',
};

const _slotWords = {
  Slot.wakeUp: 'sunrise',
  Slot.morning: 'morning light',
  Slot.lunch: 'sunny',
  Slot.afternoon: 'golden hour',
  Slot.evening: 'sunset',
  Slot.night: 'night sky stars',
};

/// Festività e ricorrenze con un'immagine riconoscibile (Italia).
(String, String)? holidayOf(DateTime t) {
  final m = t.month, d = t.day;
  if (m == 12 && d >= 24 && d <= 26) return ('christmas', 'christmas lights');
  if (m == 12 && d == 8) return ('immacolata', 'christmas tree');
  if ((m == 12 && d == 31) || (m == 1 && d == 1)) {
    return ('newyear', 'fireworks');
  }
  if (m == 1 && d == 6) return ('epiphany', 'winter village snow');
  if (m == 10 && d == 31) return ('halloween', 'halloween pumpkins');
  if (m == 8 && d == 15) return ('ferragosto', 'mediterranean sea');
  if (m == 4 && d == 25) return ('liberation', 'italian countryside');
  if (m == 6 && d == 2) return ('republic', 'italian countryside');
  if (m == 5 && d == 1) return ('mayday', 'spring meadow');
  if (m == 11 && d == 1) return ('allsaints', 'autumn leaves');
  final easter = easterSunday(t.year);
  final day = DateTime(t.year, m, d);
  if (day == easter || day == easter.add(const Duration(days: 1))) {
    return ('easter', 'spring blossom');
  }
  return null;
}

/// Sceglie il momento. [travelling] = fuso orario diverso da quello di casa
/// (o, in futuro, città diversa); [city] = nome della città, se noto.
WallpaperMoment momentFor(
  DateTime now, {
  Slot? slot,
  bool travelling = false,
  String? city,
  String? audio,
  WeatherKind? weather,
}) {
  final holiday = holidayOf(now);
  if (holiday != null) {
    return WallpaperMoment(
      MomentKind.holiday,
      'holiday:${holiday.$1}',
      holiday.$2,
    );
  }
  if (travelling) {
    final c = city?.trim();
    return c == null || c.isEmpty
        ? const WallpaperMoment(MomentKind.travel, 'travel', 'travel landscape')
        : WallpaperMoment(MomentKind.travel, 'travel:$c', '$c city');
  }
  // Meteo notevole: pioggia, neve, temporale, nebbia. Sereno e nuvoloso
  // lasciano spazio all'ora del giorno.
  final w = switch (weather) {
    WeatherKind.rain ||
    WeatherKind.drizzle ||
    WeatherKind.showers => ('rain', 'rain window'),
    WeatherKind.snow => ('snow', 'snowy street'),
    WeatherKind.storm => ('storm', 'storm clouds'),
    WeatherKind.fog => ('fog', 'foggy morning'),
    _ => null,
  };
  if (w != null) {
    return WallpaperMoment(MomentKind.weather, 'weather:${w.$1}', w.$2);
  }
  if (audio == 'headphones' || audio == 'bt') {
    return const WallpaperMoment(MomentKind.music, 'music', 'vinyl records');
  }
  final s = slot ?? slotFor(now);
  final season = seasonOf(now);
  return WallpaperMoment(
    MomentKind.daily,
    'daily:${s.name}:${season.name}',
    '${_slotWords[s]} ${_seasonWords[season]}',
  );
}

/// Indice "casuale" ma stabile per giornata: stessa ricerca e stesso giorno
/// → stessa foto; [shuffle] permette di passare alla successiva.
int pickIndex(String query, DateTime day, int count, {int shuffle = 0}) {
  if (count <= 0) return 0;
  final key = '$query|${day.year}-${day.month}-${day.day}|$shuffle';
  // FNV-1a a 32 bit: deterministico su tutte le piattaforme.
  var h = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h % count;
}
