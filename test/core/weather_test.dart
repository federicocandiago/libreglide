import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/weather.dart';

void main() {
  test('WMO codes', () {
    expect(weatherKindOf(0), WeatherKind.clear);
    expect(weatherKindOf(2), WeatherKind.partly);
    expect(weatherKindOf(45), WeatherKind.fog);
    expect(weatherKindOf(63), WeatherKind.rain);
    expect(weatherKindOf(75), WeatherKind.snow);
    expect(weatherKindOf(81), WeatherKind.showers);
    expect(weatherKindOf(95), WeatherKind.storm);
    expect(weatherKindOf(1234), WeatherKind.cloudy);
  });

  test('coordinates rounded to ~10 km', () {
    expect(roundCoordinate(45.43713), 45.4);
    expect(roundCoordinate(12.33265), 12.3);
    expect(roundCoordinate(-0.06), -0.1);
  });

  test('Open-Meteo response: now, highs, next hours every 2 hours', () {
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
        'weather_code': [3, 61],
        'precipitation_probability_max': [10, 80],
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
    expect(w.tomorrow?.kind, WeatherKind.rain);
    expect(w.tomorrow?.max, 15.0);
    expect(w.tomorrow?.rainChance, 80);
  });

  group('temperature unit', () {
    test('Fahrenheit only in the regions that use it', () {
      expect(usesFahrenheit('US'), isTrue);
      expect(usesFahrenheit('us'), isTrue);
      expect(usesFahrenheit('IT'), isFalse);
      expect(usesFahrenheit(null), isFalse);
    });

    test('rounded degrees in the chosen unit', () {
      expect(formatDegrees(12.4, fahrenheit: false), '12°');
      expect(formatDegrees(-0.6, fahrenheit: false), '-1°');
      expect(formatDegrees(20, fahrenheit: true), '68°');
    });
  });
}
