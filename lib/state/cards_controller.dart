/// Dati delle card dinamiche dello Space: Agenda e In ascolto.
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

  /// Eventi da oggi a dopodomani; null = permesso calendario mancante.
  List<CalendarEvent>? events;
  bool eventsLoaded = false;

  /// Dove è stata lasciata l'auto (solo se la funzione è attiva).
  Parking? parking;

  /// Permessi che mancano per il parcheggio, nell'ordine in cui chiederli.
  List<String> parkingMissing = const [];
  bool parkingWanted = false;

  /// La posizione in background è negata in modo definitivo.
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
      debugPrint('libreglide: parcheggio non disponibile: $e');
    }
    _notify();
  }

  /// Chiede il primo permesso mancante (uno alla volta, come vuole Android).
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

  /// Tempo di utilizzo di oggi; null senza accesso (o non richiesto).
  ScreenTime? screenTime;
  bool? usageAccess;

  /// Lo si legge solo se l'utente l'ha attivato nelle impostazioni.
  bool screenTimeWanted = false;

  Future<void> refreshScreenTime() async {
    if (!screenTimeWanted) return;
    try {
      usageAccess = await _bridge.hasUsageAccess();
      screenTime = usageAccess! ? await _bridge.screenTimeToday() : null;
    } catch (e) {
      debugPrint('libreglide: tempo di utilizzo non disponibile: $e');
    }
    _notify();
  }

  /// Accesso alle sessioni multimediali concesso.
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
          // Gli eventi del player arrivano a raffica: se ne aspetta la fine.
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

  /// Durante un aggiornamento complessivo si avvisa una volta sola, alla
  /// fine, invece che una volta per card.
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
      debugPrint('libreglide: calendario non disponibile: $e');
    }
    eventsLoaded = true;
    _notify();
  }

  Future<void> refreshMedia() async {
    try {
      final (access, info) = await _bridge.media(artSizePx: artSizePx);
      mediaAccess = access;
      // Copertina invariata: si riusa quella già decodificata.
      media = info != null && info.artUnchanged
          ? info.withArt(media?.art)
          : info;
    } catch (e) {
      debugPrint('libreglide: media non disponibili: $e');
    }
    _notify();
  }

  AgendaView? agenda() {
    final list = events;
    return list == null ? null : agendaFor(_clock(), list);
  }

  Future<void> mediaCommand(String command) async {
    await _bridge.mediaCommand(command);
    // Lo stato arriva dal callback nativo; questo copre i player lenti.
    Future<void>.delayed(const Duration(milliseconds: 400), refreshMedia);
  }
}
