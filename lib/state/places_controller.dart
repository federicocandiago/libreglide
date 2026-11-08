/// Places: a sample on every return to the launcher, home and work
/// recognition, user corrections. All local (spec-motore-contesto §6).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/places.dart';
import '../data/launch_store.dart';
import '../data/settings.dart';
import '../platform/launcher_bridge.dart';

class PlacesController extends ChangeNotifier {
  PlacesController(
    this._bridge,
    this._store,
    this._settings, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LauncherBridge _bridge;
  final LaunchStore _store;
  final SettingsController _settings;
  final DateTime Function() _clock;

  PlaceEngine engine = PlaceEngine();
  List<LocationSample> _samples = [];
  List<int?> _placeOf = [];

  /// Whether precise location permission has been granted.
  bool? permission;

  int? _currentId;
  DateTime? _currentAt;
  DateTime? _lastSample;
  DateTime? _lastFix;
  String? _lastWifi;
  DateTime? _lastInference;
  bool _busy = false;

  static const _minInterval = Duration(minutes: 3);
  static const _inferEvery = Duration(hours: 6);

  /// A place counts as "current" for 30 minutes after the last sample.
  static const _currentValidity = Duration(minutes: 30);

  Future<void> load() async {
    final json = await _store.readKv('places');
    if (json != null) {
      try {
        engine = PlaceEngine.fromJson(jsonDecode(json) as List<dynamic>);
      } catch (e) {
        debugPrint('libreglide: unreadable places state: $e');
      }
    }
    final (samples, placeOf) = await _store.loadSamples(_clock());
    _samples = samples;
    _placeOf = placeOf;
    permission = await _bridge.hasPreciseLocation();
    notifyListeners();
  }

  Future<void> _save() => _store.writeKv('places', jsonEncode(engine.toJson()));

  /// Current place, if recent.
  Place? get current {
    final at = _currentAt;
    if (at == null || _clock().difference(at) > _currentValidity) return null;
    return engine.byId(_currentId);
  }

  PlaceRole? get currentRole => current?.effectiveRole;

  Place? get home => engine.withRole(PlaceRole.home);

  /// Work or school, inferred from the hours at the work place.
  WorkKind? get workKind => engine.workKind;
  Place? get work => engine.withRole(PlaceRole.work);

  /// More than 100 km from home: travelling.
  bool get farFromHome {
    final h = home;
    if (h == null || _samples.isEmpty) return false;
    final last = _samples.last;
    if (last.lat == null || _clock().difference(last.ts) > _currentValidity) {
      return false;
    }
    return distanceMeters(h.lat, h.lon, last.lat!, last.lon!) / 1000 >
        travelDistanceKm;
  }

  Future<void> requestPermission() => _bridge.requestPreciseLocation();

  /// What the UI sees: listeners are notified only when it changes.
  String _signature() => [
    permission,
    current?.id,
    for (final p in engine.places) '${p.id}:${p.effectiveRole.name}',
  ].join('|');

  /// Takes a sample (at most every 3 minutes) and recomputes roles every
  /// 6 hours.
  Future<void> sample({bool force = false}) async {
    if (!_settings.placesEnabled || _busy) return;
    final before = _signature();
    final now = _clock();
    permission = await _bridge.hasPreciseLocation();
    if (!permission!) {
      if (_signature() != before) notifyListeners();
      return;
    }
    if (!force &&
        _lastSample != null &&
        now.difference(_lastSample!) < _minInterval) {
      return;
    }
    _busy = true;
    try {
      // Same already-recognized Wi-Fi network and a recent fix: the
      // fingerprint is enough, no need to turn on location.
      LocationSample? s;
      if (_lastFix != null &&
          now.difference(_lastFix!) < const Duration(minutes: 15)) {
        final quick = await _bridge.placeSample(withLocation: false);
        final wifi = quick?.wifi;
        if (wifi != null &&
            wifi == _lastWifi &&
            engine.places.any((p) => p.trustsWifi(wifi))) {
          s = quick;
        }
      }
      s ??= await _bridge.placeSample();
      _lastSample = now;
      if (s == null) return;
      if (s.lat != null) _lastFix = now;
      _lastWifi = s.wifi;
      final id = engine.addSample(s);
      _samples.add(s);
      _placeOf.add(id);
      await _store.insertSample(s, id);
      if (id != null) {
        _currentId = id;
        _currentAt = s.ts;
      }
      if (_lastInference == null ||
          now.difference(_lastInference!) > _inferEvery) {
        infer();
      }
      await _save();
    } catch (e) {
      debugPrint('libreglide: location sample failed: $e');
    } finally {
      _busy = false;
      if (_signature() != before) notifyListeners();
    }
  }

  void infer() {
    final now = _clock();
    engine
      ..maintain(now)
      ..inferRoles(_samples, _placeOf, now);
    _lastInference = now;
  }

  // --- User corrections ---

  Future<void> setCurrentAs(PlaceRole role) async {
    final p = current;
    if (p == null) return;
    engine.setUserRole(p.id, role);
    infer();
    await _save();
    notifyListeners();
  }

  Future<void> notThis(PlaceRole role) async {
    final p = current;
    if (p == null) return;
    engine.block(p.id, role);
    infer();
    await _save();
    notifyListeners();
  }

  Future<void> reset() async {
    engine.reset();
    _samples = [];
    _placeOf = [];
    _currentId = null;
    _currentAt = null;
    await _store.clearSamples();
    await _save();
    notifyListeners();
  }
}
