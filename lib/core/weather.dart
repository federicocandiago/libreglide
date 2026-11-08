/// Weather for the Space card: model and interpretation of the WMO codes
/// used by Open-Meteo.
library;

/// Simplified weather condition.
enum WeatherKind {
  clear,
  partly,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  showers,
  storm,
}

/// WMO code → condition.
WeatherKind weatherKindOf(int code) => switch (code) {
  0 => WeatherKind.clear,
  1 || 2 => WeatherKind.partly,
  3 => WeatherKind.cloudy,
  45 || 48 => WeatherKind.fog,
  51 || 53 || 55 || 56 || 57 => WeatherKind.drizzle,
  61 || 63 || 65 || 66 || 67 => WeatherKind.rain,
  71 || 73 || 75 || 77 || 85 || 86 => WeatherKind.snow,
  80 || 81 || 82 => WeatherKind.showers,
  95 || 96 || 99 => WeatherKind.storm,
  _ => WeatherKind.cloudy,
};

class HourForecast {
  const HourForecast(this.time, this.temperature, this.kind, this.rainChance);
  final DateTime time;
  final double temperature;
  final WeatherKind kind;

  /// Precipitation probability, 0–100.
  final int rainChance;
}

class WeatherNow {
  const WeatherNow({
    required this.fetched,
    required this.temperature,
    required this.kind,
    required this.isDay,
    required this.max,
    required this.min,
    required this.hours,
    this.tomorrow,
  });

  /// Parses the Open-Meteo response (`current`, `hourly`, `daily`, with
  /// `timezone=auto`: local times of the location, without offset).
  factory WeatherNow.fromOpenMeteo(Map<String, dynamic> j, DateTime now) {
    final current = j['current'] as Map<String, dynamic>;
    final daily = j['daily'] as Map<String, dynamic>;
    final hourly = j['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final codes = (hourly['weather_code'] as List).cast<num>();
    final rain = (hourly['precipitation_probability'] as List?)?.cast<num?>();

    // The next 4 full hours, in 2-hour steps.
    final hours = <HourForecast>[];
    final start = DateTime(now.year, now.month, now.day, now.hour + 1);
    for (var i = 0; i < times.length && hours.length < 4; i++) {
      final t = DateTime.parse(times[i]);
      if (t.isBefore(start)) continue;
      if (t.difference(start).inHours % 2 != 0) continue;
      hours.add(
        HourForecast(
          t,
          temps[i].toDouble(),
          weatherKindOf(codes[i].toInt()),
          (rain?[i] ?? 0).toInt(),
        ),
      );
    }
    return WeatherNow(
      fetched: now,
      temperature: (current['temperature_2m'] as num).toDouble(),
      kind: weatherKindOf((current['weather_code'] as num).toInt()),
      isDay: (current['is_day'] as num?)?.toInt() != 0,
      max: ((daily['temperature_2m_max'] as List).first as num).toDouble(),
      min: ((daily['temperature_2m_min'] as List).first as num).toDouble(),
      hours: hours,
      tomorrow: _tomorrow(daily),
    );
  }

  static DayForecast? _tomorrow(Map<String, dynamic> daily) {
    List<dynamic>? list(String k) => daily[k] as List<dynamic>?;
    final max = list('temperature_2m_max');
    final min = list('temperature_2m_min');
    final codes = list('weather_code');
    if (max == null || min == null || codes == null) return null;
    if (max.length < 2 || min.length < 2 || codes.length < 2) return null;
    final rain = list('precipitation_probability_max');
    return DayForecast(
      kind: weatherKindOf((codes[1] as num).toInt()),
      max: (max[1] as num).toDouble(),
      min: (min[1] as num).toDouble(),
      rainChance: rain != null && rain.length > 1
          ? ((rain[1] as num?) ?? 0).toInt()
          : 0,
    );
  }

  final DateTime fetched;
  final double temperature;
  final WeatherKind kind;
  final bool isDay;
  final double max;
  final double min;
  final List<HourForecast> hours;

  /// Tomorrow's forecast (null if the service didn't provide it).
  final DayForecast? tomorrow;
}

class DayForecast {
  const DayForecast({
    required this.kind,
    required this.max,
    required this.min,
    required this.rainChance,
  });

  final WeatherKind kind;
  final double max;
  final double min;

  /// Maximum chance of rain during the day, as a percentage.
  final int rainChance;
}

/// Rounds a coordinate to 1 decimal (~10 km): the weather service doesn't
/// need to know precisely where you are.
double roundCoordinate(double v) => (v * 10).round() / 10;

// --- Temperature unit ---

/// Regions that use Fahrenheit (ISO 3166 country codes).
const _fahrenheitRegions = {
  'US',
  'LR',
  'MM',
  'BS',
  'BZ',
  'KY',
  'PW',
  'FM',
  'MH',
};

/// Whether temperatures are shown in Fahrenheit in [countryCode].
bool usesFahrenheit(String? countryCode) =>
    _fahrenheitRegions.contains(countryCode?.toUpperCase());

/// [celsius] in the unit of the region, rounded, with the degree sign.
String formatDegrees(double celsius, {required bool fahrenheit}) =>
    '${(fahrenheit ? celsius * 9 / 5 + 32 : celsius).round()}°';
