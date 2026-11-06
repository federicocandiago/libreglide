/// Client Open-Meteo (https://open-meteo.com): meteo gratuito, senza chiave.
///
/// Secondo e ultimo punto dell'app che usa la rete, insieme a
/// `unsplash.dart`. Viene chiamato solo se l'utente attiva la card Meteo.
/// Invia soltanto coordinate arrotondate a ~10 km e i normali dati tecnici
/// della connessione. Dati meteo: Open-Meteo, licenza CC BY 4.0.
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
      throw Exception('Open-Meteo: risposta ${r.statusCode}');
    }
    return WeatherNow.fromOpenMeteo(
      jsonDecode(r.body) as Map<String, dynamic>,
      now,
    );
  }

  void close() => _http.close();
}
