/// Meteo per la card dello Space: modello e interpretazione dei codici WMO
/// usati da Open-Meteo.
library;

/// Condizione meteo semplificata.
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

/// Codice WMO → condizione.
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

  /// Probabilità di precipitazione, 0–100.
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
  });

  /// Interpreta la risposta di Open-Meteo (`current`, `hourly`, `daily`,
  /// con `timezone=auto`: orari locali del luogo, senza fuso).
  factory WeatherNow.fromOpenMeteo(Map<String, dynamic> j, DateTime now) {
    final current = j['current'] as Map<String, dynamic>;
    final daily = j['daily'] as Map<String, dynamic>;
    final hourly = j['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final codes = (hourly['weather_code'] as List).cast<num>();
    final rain = (hourly['precipitation_probability'] as List?)?.cast<num?>();

    // Le prossime 4 ore piene, a passi di 2 ore.
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
    );
  }

  final DateTime fetched;
  final double temperature;
  final WeatherKind kind;
  final bool isDay;
  final double max;
  final double min;
  final List<HourForecast> hours;
}

/// Arrotonda una coordinata a 1 decimale (~10 km): al servizio meteo non
/// serve sapere dove sei con precisione.
double roundCoordinate(double v) => (v * 10).round() / 10;
