/// Open-Meteo client (https://open-meteo.com): free weather, no API key.
///
/// The second and last place in the app that uses the network, together
/// with `unsplash.dart`. Called only if the user enables the Weather card.
/// Sends only coordinates rounded to ~10 km and the usual technical
/// connection data. Weather data: Open-Meteo, CC BY 4.0 license.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/weather.dart';

class OpenMeteoClient {
  OpenMeteoClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  Future<WeatherNow> forecast(double lat, double lon, DateTime now) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': roundCoordinate(lat).toStringAsFixed(1),
      'longitude': roundCoordinate(lon).toStringAsFixed(1),
      'current': 'temperature_2m,weather_code,is_day',
      'hourly': 'temperature_2m,weather_code,precipitation_probability',
      'daily':
          'temperature_2m_max,temperature_2m_min,weather_code,'
          'precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '2',
    });
    final r = await _http.get(uri).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('Open-Meteo: response ${r.statusCode}');
    }
    return WeatherNow.fromOpenMeteo(
      jsonDecode(r.body) as Map<String, dynamic>,
      now,
    );
  }

  void close() => _http.close();
}
