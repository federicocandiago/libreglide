/// Moment of the day for the contextual wallpaper, and Unsplash keywords,
/// chosen deterministically (same context → same search).
///
/// Priority: holiday → travel → notable weather → music → time slot +
/// season.
/// Keywords are in English because they work better on Unsplash.
library;

import 'time_context.dart';
import 'weather.dart';

enum MomentKind { holiday, travel, weather, music, daily }

class WallpaperMoment {
  const WallpaperMoment(this.kind, this.id, this.query);

  final MomentKind kind;

  /// Stable identifier of the moment (e.g. `holiday:christmas`,
  /// `daily:evening:autumn`).
  final String id;

  /// Unsplash search query.
  final String query;

  @override
  String toString() => '$id → "$query"';
}

enum Season { winter, spring, summer, autumn }

/// Meteorological season (northern hemisphere).
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

/// Holidays and occasions with a recognizable image (Italy).
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

/// Picks the moment. [travelling] = time zone different from home (or, in
/// the future, a different city); [city] = city name, if known.
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
  // Notable weather: rain, snow, storm, fog. Clear and cloudy skies give
  // way to the time of day.
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

/// "Random" but stable index per day: same query and same day → same
/// photo; [shuffle] moves on to the next one.
int pickIndex(String query, DateTime day, int count, {int shuffle = 0}) {
  if (count <= 0) return 0;
  final key = '$query|${day.year}-${day.month}-${day.day}|$shuffle';
  // 32-bit FNV-1a: deterministic on all platforms.
  var h = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h % count;
}

// --- Daily wallpaper and photo style ---

/// Photo style chosen by the user, added to every Unsplash search.
/// [word] stays in English (it works better on Unsplash); the labels shown
/// in the app are translated.
enum WallpaperStyle {
  none(null),
  aesthetic('aesthetic'),
  nature('nature'),
  minimal('minimal'),
  abstract('abstract'),
  architecture('architecture'),
  dark('dark');

  const WallpaperStyle(this.word);

  final String? word;

  /// The style saved in settings, or [none] if unknown.
  static WallpaperStyle byName(String? name) => WallpaperStyle.values
      .firstWhere((s) => s.name == name, orElse: () => WallpaperStyle.none);
}

/// Query for the daily wallpaper: the style plus "wallpaper", which keeps
/// results close to phone wallpapers (a fully random Unsplash photo can be
/// anything, from a product shot to a portrait).
String dailyQuery(WallpaperStyle style) =>
    style.word == null ? 'wallpaper' : '${style.word} wallpaper';

/// [query] with the style word appended (unchanged for [WallpaperStyle.none]).
String withStyle(String query, WallpaperStyle style) =>
    style.word == null ? query : '$query ${style.word}';
