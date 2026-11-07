/// Data for the Space's dynamic cards: Agenda and Now playing.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/agenda.dart';
import '../platform/launcher_bridge.dart';

class CardsController extends ChangeNotifier {
  CardsController(this._bridge, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LauncherBridge _bridge;
  final DateTime Function() _clock;

  /// Events from today to the day after tomorrow; null = calendar permission
  /// missing.
  List<CalendarEvent>? events;
  bool eventsLoaded = false;

  /// Where the car was parked (only if the feature is enabled).
  Parking? parking;

  /// Permissions still missing for parking, in the order to request them.
  List<String> parkingMissing = const [];
  bool parkingWanted = false;

  /// Background location has been permanently denied.
  bool parkingBlocked = false;

  Future<void> refreshParking() async {
    if (!parkingWanted) {
      parking = null;
      return;
    }
    try {
      parking = await _bridge.parking();
      parkingMissing = [
        if (!await _bridge.hasBluetooth()) 'bluetooth',
        if (!await _bridge.hasPreciseLocation()) 'precise',
        if (!await _bridge.hasBackgroundLocation()) 'background',
      ];
      parkingBlocked =
          parkingMissing.firstOrNull == 'background' &&
          await _bridge.backgroundLocationBlocked();
    } catch (e) {
      debugPrint('libreglide: parking unavailable: $e');
    }
    _notify();
  }

  /// Requests the first missing permission (one at a time, as Android
  /// requires).
  Future<void> requestNextParkingPermission() async {
    switch (parkingMissing.firstOrNull) {
      case 'bluetooth':
        await _bridge.requestBluetooth();
      case 'precise':
        await _bridge.requestPreciseLocation();
      case 'background':
        await _bridge.requestBackgroundLocation();
    }
  }

  Future<void> forgetParking() async {
    await _bridge.clearParking();
    parking = null;
    _notify();
  }

  /// Today's screen time; null without access (or when not requested).
  ScreenTime? screenTime;
  bool? usageAccess;

  /// Only read if the user enabled it in settings.
  bool screenTimeWanted = false;

  Future<void> refreshScreenTime() async {
    if (!screenTimeWanted) return;
    try {
      usageAccess = await _bridge.hasUsageAccess();
      screenTime = usageAccess! ? await _bridge.screenTimeToday() : null;
    } catch (e) {
      debugPrint('libreglide: screen time unavailable: $e');
    }
    _notify();
  }

  /// Whether access to media sessions has been granted.
  bool mediaAccess = false;
  MediaInfo? media;

  final List<StreamSubscription<void>> _subs = [];
  Timer? _timer;
  Timer? _mediaDebounce;
  int artSizePx = 192;

  void start() {
    _subs
      ..add(_bridge.resumed.listen((_) => refresh()))
      ..add(
        _bridge.mediaChanged.listen((_) {
          // Player events arrive in bursts: wait for them to settle.
          _mediaDebounce?.cancel();
          _mediaDebounce = Timer(
            const Duration(milliseconds: 250),
            refreshMedia,
          );
        }),
      );
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => refreshEvents());
    refresh();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _timer?.cancel();
    _mediaDebounce?.cancel();
    super.dispose();
  }

  /// During a full refresh listeners are notified once, at the end, instead
  /// of once per card.
  int _batch = 0;
  bool _pending = false;

  void _notify() {
    if (_batch > 0) {
      _pending = true;
    } else {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _batch++;
    try {
      await Future.wait([
        refreshEvents(),
        refreshMedia(),
        refreshScreenTime(),
        refreshParking(),
      ]);
    } finally {
      _batch--;
      if (_batch == 0 && _pending) {
        _pending = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshEvents() async {
    final now = _clock();
    final from = DateTime(now.year, now.month, now.day);
    try {
      events = await _bridge.events(from, from.add(const Duration(days: 2)));
    } catch (e) {
      debugPrint('libreglide: calendar unavailable: $e');
    }
    eventsLoaded = true;
    _notify();
  }

  Future<void> refreshMedia() async {
    try {
      final (access, info) = await _bridge.media(artSizePx: artSizePx);
      mediaAccess = access;
      // Artwork unchanged: reuse the already decoded one.
      media = info != null && info.artUnchanged
          ? info.withArt(media?.art)
          : info;
    } catch (e) {
      debugPrint('libreglide: media unavailable: $e');
    }
    _notify();
  }

  AgendaView? agenda() {
    final list = events;
    return list == null ? null : agendaFor(_clock(), list);
  }

  Future<void> mediaCommand(String command) async {
    await _bridge.mediaCommand(command);
    // State arrives via the native callback; this covers slow players.
    Future<void>.delayed(const Duration(milliseconds: 400), refreshMedia);
  }
}
