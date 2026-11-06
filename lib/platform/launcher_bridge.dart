/// Lato Dart del bridge Kotlin `LauncherBridge`.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/agenda.dart';
import '../core/app_entry.dart';
import '../core/contact.dart';
import '../core/places.dart';

class AppIcon {
  const AppIcon({required this.icon, this.mono});

  /// Icona originale in PNG.
  final Uint8List icon;

  /// Layer monocromo (maschera bianca in PNG), solo Android 13+.
  final Uint8List? mono;
}

/// Dove è stata lasciata l'auto.
class Parking {
  const Parking({
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.at,
    required this.precise,
  });

  final double lat;
  final double lon;

  /// Precisione in metri.
  final double accuracy;
  final DateTime at;

  /// Posizione presa al momento dello scollegamento (non l'ultima nota).
  final bool precise;
}

/// Tempo di utilizzo di oggi: totale e app più usate.
class ScreenTime {
  const ScreenTime({required this.total, required this.top});
  final Duration total;
  final List<(String, Duration)> top;
}

/// Un widget installato che si può aggiungere.
class WidgetProvider {
  const WidgetProvider({
    required this.provider,
    required this.package,
    required this.label,
    required this.minWidth,
    required this.minHeight,
  });

  factory WidgetProvider.fromMap(Map<Object?, Object?> m) => WidgetProvider(
    provider: m['provider']! as String,
    package: m['package']! as String,
    label: (m['label'] as String?) ?? '',
    minWidth: (m['minWidth'] as num?)?.toInt() ?? 0,
    minHeight: (m['minHeight'] as num?)?.toInt() ?? 0,
  );

  final String provider;
  final String package;
  final String label;
  final int minWidth;
  final int minHeight;
}

/// Un widget aggiunto allo Space.
class PlacedWidget {
  const PlacedWidget({
    required this.id,
    required this.label,
    required this.package,
    required this.height,
  });

  factory PlacedWidget.fromJson(Map<String, dynamic> j) => PlacedWidget(
    id: j['id'] as int,
    label: j['label'] as String,
    package: j['package'] as String,
    height: (j['height'] as num).toDouble(),
  );

  final int id;
  final String label;
  final String package;

  /// Altezza della card in dp.
  final double height;

  PlacedWidget withHeight(double h) =>
      PlacedWidget(id: id, label: label, package: package, height: h);

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'package': package,
    'height': height,
  };
}

/// Brano in riproduzione.
class MediaInfo {
  const MediaInfo({
    required this.title,
    this.artist,
    required this.package,
    required this.playing,
    this.canPrevious = true,
    this.canNext = true,
    this.art,
    this.artUnchanged = false,
  });

  factory MediaInfo.fromMap(Map<Object?, Object?> m) => MediaInfo(
    title: m['title'] as String,
    artist: m['artist'] as String?,
    package: m['package'] as String,
    playing: (m['playing'] as bool?) ?? false,
    canPrevious: (m['canPrevious'] as bool?) ?? true,
    canNext: (m['canNext'] as bool?) ?? true,
    art: m['art'] is Uint8List ? m['art'] as Uint8List : null,
    artUnchanged: m['artSame'] == true,
  );

  /// Stessa informazione con la copertina già nota.
  MediaInfo withArt(Uint8List? a) => MediaInfo(
    title: title,
    artist: artist,
    package: package,
    playing: playing,
    canPrevious: canPrevious,
    canNext: canNext,
    art: a,
  );

  final String title;
  final String? artist;
  final String package;
  final bool playing;
  final bool canPrevious;
  final bool canNext;
  final Uint8List? art;

  /// La copertina non è cambiata dall'ultima volta (non è stata inviata).
  final bool artUnchanged;
}

class LauncherBridge {
  LauncherBridge() {
    _methods.setMethodCallHandler(_onNativeCall);
  }

  static const _methods = MethodChannel('libreglide/launcher');
  static const _events = EventChannel('libreglide/launcher/events');

  final _homePressed = StreamController<void>.broadcast();
  final _resumed = StreamController<void>.broadcast();
  final _open = StreamController<String>.broadcast();

  /// Schermata da aprire (comando di sviluppo via adb, extra `open`):
  /// home, space, collections, az, search, drawer, settings, colors,
  /// hidden, diagnostics.
  Stream<String> get openRequests => _open.stream;

  /// Tasto o gesto Home con il launcher già in primo piano.
  Stream<void> get homePressed => _homePressed.stream;

  /// L'activity del launcher è tornata in primo piano.
  Stream<void> get resumed => _resumed.stream;

  /// Un solo flusso dal canale nativo, condiviso da tutti gli ascoltatori:
  /// un secondo `receiveBroadcastStream` ruberebbe il canale al primo.
  late final Stream<Map<Object?, Object?>> _eventStream = _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .cast<Map<Object?, Object?>>()
      .asBroadcastStream();

  /// App installate, aggiornate o rimosse.
  late final Stream<String?> packagesChanged = _eventStream
      .where((e) => e['type'] == 'packages_changed')
      .map((e) => e['package'] as String?);

  /// La musica in riproduzione è cambiata.
  late final Stream<void> mediaChanged = _eventStream
      .where((e) => e['type'] == 'media_changed')
      .map((_) {});

  Future<void> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onHomePressed':
        _homePressed.add(null);
      case 'onResumed':
        _resumed.add(null);
      case 'onBlurAvailable':
        blurAvailable.value = call.arguments == true;
      case 'onOpen':
        if (call.arguments case final String target) _open.add(target);
    }
  }

  /// La sfocatura di sistema è disponibile (non lo è, per esempio, in
  /// risparmio energetico).
  final ValueNotifier<bool> blurAvailable = ValueNotifier(true);

  /// Attiva o spegne il vetro smerigliato (finestra traslucida).
  Future<void> setGlass(bool enabled) async {
    blurAvailable.value =
        await _methods.invokeMethod<bool>('setGlass', {'enabled': enabled}) ??
        false;
  }

  /// Sfocatura dello sfondo dietro la finestra, in dp (0 = nitido).
  Future<void> setWindowBlur(double dp) =>
      _methods.invokeMethod<bool>('setWindowBlur', {'dp': dp});

  Future<List<AppEntry>> getApps() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'getApps',
    );
    return [for (final m in raw ?? const []) AppEntry.fromMap(m)];
  }

  /// Icone per gli [ids] indicati, renderizzate a [sizePx] pixel fisici.
  Future<Map<String, AppIcon>> getIcons(List<String> ids, int sizePx) async {
    final raw = await _methods.invokeMapMethod<String, Object?>('getIcons', {
      'ids': ids,
      'size': sizePx,
    });
    final out = <String, AppIcon>{};
    raw?.forEach((id, value) {
      if (value is! Map) return;
      final icon = value['icon'];
      if (icon is! Uint8List) return;
      final mono = value['mono'];
      out[id] = AppIcon(icon: icon, mono: mono is Uint8List ? mono : null);
    });
    return out;
  }

  /// Avvia l'app. [bounds] è il rettangolo dell'icona in pixel fisici
  /// (sinistra, alto, destra, basso) per l'animazione di apertura.
  Future<bool> launch(String id, {List<int>? bounds}) async =>
      await _methods.invokeMethod<bool>('launch', {
        'id': id,
        'bounds': bounds,
      }) ??
      false;

  Future<bool> openAppInfo(String id) async =>
      await _methods.invokeMethod<bool>('openAppInfo', {'id': id}) ?? false;

  Future<bool> uninstall(String package) async =>
      await _methods.invokeMethod<bool>('uninstall', {'package': package}) ??
      false;

  Future<bool> openUrl(String url) async =>
      await _methods.invokeMethod<bool>('openUrl', {'url': url}) ?? false;

  Future<bool> openSystemSettings() async =>
      await _methods.invokeMethod<bool>('openSystemSettings') ?? false;

  /// Segnali di contesto senza permessi: `network` (wifi, mobile, offline),
  /// `audio` (speaker, headphones, bt), `charging`.
  Future<Map<String, Object?>> contextSnapshot() async =>
      await _methods.invokeMapMethod<String, Object?>('getContextSnapshot') ??
      const {};

  // region Calendario
  /// Eventi tra [from] e [to]; null se manca il permesso calendario.
  Future<List<CalendarEvent>?> events(DateTime from, DateTime to) async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'getEvents',
      {'from': from.millisecondsSinceEpoch, 'to': to.millisecondsSinceEpoch},
    );
    return raw == null ? null : [for (final m in raw) CalendarEvent.fromMap(m)];
  }

  Future<bool> requestCalendar() async =>
      await _methods.invokeMethod<bool>('requestCalendar') ?? false;

  Future<bool> openEvent(CalendarEvent e) async =>
      await _methods.invokeMethod<bool>('openEvent', {
        'id': e.id,
        'begin': e.begin.millisecondsSinceEpoch,
        'end': e.end.millisecondsSinceEpoch,
      }) ??
      false;

  Future<bool> newEvent() async =>
      await _methods.invokeMethod<bool>('newEvent') ?? false;

  Future<bool> navigateTo(String query) async =>
      await _methods.invokeMethod<bool>('navigateTo', {'query': query}) ??
      false;
  // endregion

  // region Tempo di utilizzo
  Future<bool> hasUsageAccess() async =>
      await _methods.invokeMethod<bool>('hasUsageAccess') ?? false;

  /// Aperture di app dalla cronologia di Android da [since]: (pacchetto, ora).
  Future<List<(String, DateTime)>> usageOpenings(DateTime since) async {
    final list = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'usageOpenings',
      {'since': since.millisecondsSinceEpoch},
    );
    return [
      for (final m in list ?? const <Map<Object?, Object?>>[])
        (
          m['package'] as String,
          DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        ),
    ];
  }

  Future<bool> openUsageAccess() async =>
      await _methods.invokeMethod<bool>('openUsageAccess') ?? false;

  /// Tempo di utilizzo di oggi; null senza l'accesso ai dati di utilizzo.
  Future<ScreenTime?> screenTimeToday() async {
    final m = await _methods.invokeMapMethod<String, Object?>(
      'screenTimeToday',
    );
    if (m == null) return null;
    return ScreenTime(
      total: Duration(milliseconds: (m['totalMs']! as num).toInt()),
      top: [
        for (final e in (m['top'] as List?) ?? const [])
          (
            (e as Map)['package'] as String,
            Duration(milliseconds: (e['ms'] as num).toInt()),
          ),
      ],
    );
  }
  // endregion

  // region Widget Android
  Future<List<WidgetProvider>> widgetProviders() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'widgetProviders',
    );
    return [for (final m in raw ?? const []) WidgetProvider.fromMap(m)];
  }

  /// Avvia il flusso di sistema; restituisce il widget aggiunto o null.
  Future<PlacedWidget?> addWidget(WidgetProvider p) async {
    final m = await _methods.invokeMapMethod<String, Object?>('addWidget', {
      'provider': p.provider,
    });
    if (m == null) return null;
    return PlacedWidget(
      id: (m['id']! as num).toInt(),
      label: (m['label'] as String?) ?? p.label,
      package: p.package,
      height: ((m['minHeight'] as num?)?.toDouble() ?? 110).clamp(90, 400),
    );
  }

  Future<void> removeWidget(int id) =>
      _methods.invokeMethod<bool>('removeWidget', {'id': id});
  // endregion

  // region Parcheggio
  Future<Parking?> parking() async {
    final m = await _methods.invokeMapMethod<String, Object?>('getParking');
    if (m == null) return null;
    return Parking(
      lat: (m['lat']! as num).toDouble(),
      lon: (m['lon']! as num).toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0,
      at: DateTime.fromMillisecondsSinceEpoch((m['ts']! as num).toInt()),
      precise: m['precise'] == true,
    );
  }

  Future<void> clearParking() => _methods.invokeMethod<bool>('clearParking');

  Future<void> setParkingEnabled(bool enabled) =>
      _methods.invokeMethod<bool>('setParkingEnabled', {'enabled': enabled});

  Future<bool> hasBackgroundLocation() async =>
      await _methods.invokeMethod<bool>('hasBackgroundLocation') ?? false;

  // Digital detox
  Future<void> detoxSync(Map<String, Object?> config) =>
      _methods.invokeMethod<bool>('detoxSync', config);

  Future<bool> detoxHasPin() async =>
      await _methods.invokeMethod<bool>('detoxHasPin') ?? false;

  Future<void> detoxSetPin(String pin) =>
      _methods.invokeMethod<bool>('detoxSetPin', {'pin': pin});

  /// 0 = giusto, -1 = sbagliato, altrimenti millisecondi di attesa.
  Future<int> detoxCheckPin(String pin) async =>
      await _methods.invokeMethod<int>('detoxCheckPin', {'pin': pin}) ?? -1;

  Future<void> detoxPreview() => _methods.invokeMethod<bool>('detoxPreview');

  Future<bool> detoxServiceEnabled() async =>
      await _methods.invokeMethod<bool>('detoxServiceEnabled') ?? false;

  Future<bool> openDetoxService() async =>
      await _methods.invokeMethod<bool>('openDetoxService') ?? false;

  /// App di sistema delicate installate: (pacchetto, nome).
  Future<List<(String, String)>> detoxSystemApps() async {
    final list = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'detoxSystemApps',
    );
    return [
      for (final m in list ?? const <Map<Object?, Object?>>[])
        (m['package'] as String, m['label'] as String),
    ];
  }

  /// La posizione in background è stata negata e Android non la richiede
  /// più: va concessa dalle impostazioni dell'app.
  Future<bool> backgroundLocationBlocked() async =>
      await _methods.invokeMethod<bool>('backgroundLocationBlocked') ?? false;

  Future<bool> requestBackgroundLocation() async =>
      await _methods.invokeMethod<bool>('requestBackgroundLocation') ?? false;
  // endregion

  // region Luoghi
  Future<bool> hasPreciseLocation() async =>
      await _methods.invokeMethod<bool>('hasPreciseLocation') ?? false;

  Future<bool> requestPreciseLocation() async =>
      await _methods.invokeMethod<bool>('requestPreciseLocation') ?? false;

  /// Campione per i luoghi (posizione precisa, impronta Wi-Fi, ricarica),
  /// o null senza permesso o senza dati.
  Future<LocationSample?> placeSample({bool withLocation = true}) async {
    final m = await _methods.invokeMapMethod<String, Object?>('placeSample', {
      'withLocation': withLocation,
    });
    if (m == null) return null;
    return LocationSample(
      ts: DateTime.now(),
      lat: (m['lat'] as num?)?.toDouble(),
      lon: (m['lon'] as num?)?.toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble(),
      wifi: m['wifi'] as String?,
      charging: m['charging'] == true,
    );
  }
  // endregion

  // region Posizione approssimativa e Bluetooth
  Future<bool> hasLocation() async =>
      await _methods.invokeMethod<bool>('hasLocation') ?? false;

  Future<bool> requestLocation() async =>
      await _methods.invokeMethod<bool>('requestLocation') ?? false;

  /// Posizione approssimativa (lat, lon), o null.
  Future<(double, double)?> coarseLocation() async {
    final m = await _methods.invokeMapMethod<String, Object?>('coarseLocation');
    if (m == null) return null;
    return ((m['lat']! as num).toDouble(), (m['lon']! as num).toDouble());
  }

  Future<bool> hasBluetooth() async =>
      await _methods.invokeMethod<bool>('hasBluetooth') ?? false;

  Future<bool> requestBluetooth() async =>
      await _methods.invokeMethod<bool>('requestBluetooth') ?? false;
  // endregion

  // region Contatti
  Future<bool> hasContacts() async =>
      await _methods.invokeMethod<bool>('hasContacts') ?? false;

  Future<bool> requestContacts() async =>
      await _methods.invokeMethod<bool>('requestContacts') ?? false;

  Future<List<Contact>> _contacts(String method, [Object? args]) async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      method,
      args,
    );
    return [for (final m in raw ?? const []) Contact.fromMap(m)];
  }

  Future<List<Contact>> starredContacts() => _contacts('starredContacts');

  Future<List<Contact>> contactsByLookup(List<String> keys) =>
      _contacts('contactsByLookup', {'keys': keys});

  Future<List<Contact>> searchContacts(String query) =>
      _contacts('searchContacts', {'query': query});

  /// Apre il tastierino con il numero: la chiamata la avvia l'utente.
  Future<bool> dial(String number) async =>
      await _methods.invokeMethod<bool>('dial', {'number': number}) ?? false;

  Future<bool> sms(String number) async =>
      await _methods.invokeMethod<bool>('sms', {'number': number}) ?? false;

  Future<bool> openContact(Contact c) async =>
      await _methods.invokeMethod<bool>('openContact', {
        'id': c.id,
        'lookupKey': c.lookupKey,
      }) ??
      false;
  // endregion

  // region Media
  /// Accesso ai media e brano corrente (null se non c'è nulla).
  Future<(bool, MediaInfo?)> media({int artSizePx = 192}) async {
    final raw = await _methods.invokeMapMethod<String, Object?>('getMedia', {
      'artSize': artSizePx,
    });
    final access = (raw?['access'] as bool?) ?? false;
    final m = raw?['media'];
    return (access, m is Map ? MediaInfo.fromMap(m) : null);
  }

  /// `playPause`, `next`, `previous`.
  Future<bool> mediaCommand(String command) async =>
      await _methods.invokeMethod<bool>('mediaCommand', {'command': command}) ??
      false;

  Future<bool> openMediaAccess() async =>
      await _methods.invokeMethod<bool>('openMediaAccess') ?? false;
  // endregion

  /// Scarto dall'UTC del fuso [tz] adesso (ora legale inclusa).
  Future<Duration> timeZoneOffset(String tz) async => Duration(
    milliseconds:
        await _methods.invokeMethod<int>('timeZoneOffset', {'tz': tz}) ?? 0,
  );

  /// Prossima sveglia impostata (qualsiasi app sveglia), o null.
  Future<DateTime?> nextAlarm() async {
    final ms = await _methods.invokeMethod<int>('getNextAlarm');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<bool> openAlarms() async =>
      await _methods.invokeMethod<bool>('openAlarms') ?? false;

  /// Timer dell'orologio (o le sveglie, se l'orologio non li espone).
  Future<bool> openTimers() async =>
      await _methods.invokeMethod<bool>('openTimers') ?? false;

  Future<bool> openDoNotDisturb() async =>
      await _methods.invokeMethod<bool>('openDoNotDisturb') ?? false;

  Future<bool> isDefaultHome() async =>
      await _methods.invokeMethod<bool>('isDefaultHome') ?? false;

  Future<bool> requestDefaultHome() async =>
      await _methods.invokeMethod<bool>('requestDefaultHome') ?? false;
}
