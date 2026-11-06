import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/weather.dart';

void main() {
  test('codici WMO', () {
    expect(weatherKindOf(0), WeatherKind.clear);
    expect(weatherKindOf(2), WeatherKind.partly);
    expect(weatherKindOf(45), WeatherKind.fog);
    expect(weatherKindOf(63), WeatherKind.rain);
    expect(weatherKindOf(75), WeatherKind.snow);
    expect(weatherKindOf(81), WeatherKind.showers);
    expect(weatherKindOf(95), WeatherKind.storm);
    expect(weatherKindOf(1234), WeatherKind.cloudy);
  });

  test('coordinate arrotondate a ~10 km', () {
    expect(roundCoordinate(45.43713), 45.4);
    expect(roundCoordinate(12.33265), 12.3);
    expect(roundCoordinate(-0.06), -0.1);
  });

  test('risposta Open-Meteo: ora, massime e prossime ore ogni 2 ore', () {
    final now = DateTime(2026, 11, 5, 18, 20);
    final times = [
      for (var h = 0; h < 30; h++)
        DateTime(2026, 11, 5, h).toIso8601String().substring(0, 16),
    ];
    final j = <String, dynamic>{
      'current': {'temperature_2m': 11.4, 'weather_code': 3, 'is_day': 0},
      'daily': {
        'temperature_2m_max': [14.2, 15.0],
        'temperature_2m_min': [7.1, 6.0],
      },
      'hourly': {
        'time': times,
        'temperature_2m': [for (var h = 0; h < 30; h++) h.toDouble()],
        'weather_code': [for (var h = 0; h < 30; h++) h < 20 ? 3 : 61],
        'precipitation_probability': [for (var h = 0; h < 30; h++) h],
      },
    };
    final w = WeatherNow.fromOpenMeteo(j, now);
    expect(w.temperature, 11.4);
    expect(w.kind, WeatherKind.cloudy);
    expect(w.isDay, isFalse);
    expect(w.max, 14.2);
    expect([for (final h in w.hours) h.time.hour], [19, 21, 23, 1]);
    expect(w.hours[1].kind, WeatherKind.rain);
    expect(w.hours[1].rainChance, 21);
  });
}
