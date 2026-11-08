/// Weather card: coarse location → Open-Meteo, at most every 30 minutes, and
/// only if the user enabled it in settings.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/weather.dart';
import '../data/settings.dart';
import '../net/open_meteo.dart';
import '../platform/launcher_bridge.dart';

class WeatherController extends ChangeNotifier {
  WeatherController(this._bridge, this._settings, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LauncherBridge _bridge;
  final SettingsController _settings;
  final DateTime Function() _clock;

  WeatherNow? weather;

  /// Whether coarse location permission has been granted.
  bool? permission;
  bool _busy = false;
  DateTime? _lastAttempt;
  StreamSubscription<void>? _resumeSub;

  /// A forecast younger than this is kept: at most one call every 30
  /// minutes, and only when the user comes back to the launcher.
  static const refreshEvery = Duration(minutes: 30);

  /// After a failed call (offline, no location), wait this long.
  static const retryAfter = Duration(minutes: 15);

  void start() {
    _resumeSub = _bridge.resumed.listen((_) => refresh());
    _settings.addListener(_onSettings);
    refresh();
  }

  @override
  void dispose() {
    _resumeSub?.cancel();
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  bool _wasOn = false;
  void _onSettings() {
    final on = _settings.weatherCard;
    if (on && !_wasOn) refresh(force: true);
    if (!on && weather != null) {
      weather = null;
      notifyListeners();
    }
    _wasOn = on;
  }

  Future<void> requestPermission() => _bridge.requestLocation();

  Future<void> refresh({bool force = false}) async {
    _wasOn = _settings.weatherCard;
    if (!_settings.weatherCard || _busy) return;
    final now = _clock();
    final had = permission;
    permission = await _bridge.hasLocation();
    if (!permission!) {
      if (had != permission) notifyListeners();
      return;
    }
    final fresh =
        weather != null && now.difference(weather!.fetched) < refreshEvery;
    final recentlyTried =
        _lastAttempt != null && now.difference(_lastAttempt!) < retryAfter;
    if (!force && (fresh || recentlyTried)) return;
    _busy = true;
    _lastAttempt = now;
    final client = OpenMeteoClient();
    try {
      final position = await _bridge.coarseLocation();
      if (position != null) {
        weather = await client.forecast(position.$1, position.$2, now);
      }
    } catch (e) {
      debugPrint('libreglide: weather unavailable: $e');
    } finally {
      client.close();
      _busy = false;
      notifyListeners();
    }
  }
}
