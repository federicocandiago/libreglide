/// Dart side of the Kotlin `LauncherBridge`.
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

  /// Original icon as PNG.
  final Uint8List icon;

  /// Monochrome layer (white mask as PNG), Android 13+ only.
  final Uint8List? mono;
}

/// Where the car was left.
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

  /// Accuracy in meters.
  final double accuracy;
  final DateTime at;

  /// Location taken at the moment of disconnection (not the last known one).
  final bool precise;
}

/// Today's screen time: total and most used apps.
class ScreenTime {
  const ScreenTime({required this.total, required this.top});
  final Duration total;
  final List<(String, Duration)> top;
}

/// An installed widget that can be added.
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

/// A widget added to the Space.
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

  /// Card height in dp.
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

/// Track currently playing.
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

  /// The same info with the already known artwork.
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

  /// The artwork hasn't changed since last time (it wasn't sent).
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

  /// Screen to open (developer command via adb, `open` extra):
  /// home, space, collections, az, search, drawer, settings, colors,
  /// hidden, diagnostics.
  Stream<String> get openRequests => _open.stream;

  /// Home button or gesture while the launcher is already in the foreground.
  Stream<void> get homePressed => _homePressed.stream;

  /// The launcher activity came back to the foreground.
  Stream<void> get resumed => _resumed.stream;

  /// A single stream from the native channel, shared by all listeners: a
  /// second `receiveBroadcastStream` would steal the channel from the first.
  late final Stream<Map<Object?, Object?>> _eventStream = _events
      .receiveBroadcastStream()
      .where((e) => e is Map)
      .cast<Map<Object?, Object?>>()
      .asBroadcastStream();

  /// Apps installed, updated or removed.
  late final Stream<String?> packagesChanged = _eventStream
      .where((e) => e['type'] == 'packages_changed')
      .map((e) => e['package'] as String?);

  /// The music playing has changed.
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

  /// Whether system blur is available (it isn't, for example, in battery
  /// saver mode).
  final ValueNotifier<bool> blurAvailable = ValueNotifier(true);

  /// Turns frosted glass (translucent window) on or off.
  Future<void> setGlass(bool enabled) async {
    blurAvailable.value =
        await _methods.invokeMethod<bool>('setGlass', {'enabled': enabled}) ??
        false;
  }

  /// Blur of the wallpaper behind the window, in dp (0 = sharp).
  Future<void> setWindowBlur(double dp) =>
      _methods.invokeMethod<bool>('setWindowBlur', {'dp': dp});

  Future<List<AppEntry>> getApps() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'getApps',
    );
    return [for (final m in raw ?? const []) AppEntry.fromMap(m)];
  }

  /// Icons for the given [ids], rendered at [sizePx] physical pixels.
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

  /// Launches the app. [bounds] is the icon rectangle in physical pixels
  /// (left, top, right, bottom) for the opening animation.
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

  /// Context signals that need no permissions: `network` (wifi, mobile,
  /// offline), `audio` (speaker, headphones, bt), `charging`.
  Future<Map<String, Object?>> contextSnapshot() async =>
      await _methods.invokeMapMethod<String, Object?>('getContextSnapshot') ??
      const {};

  // region Calendar
  /// Events between [from] and [to]; null without calendar permission.
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

  // region Screen time
  Future<bool> hasUsageAccess() async =>
      await _methods.invokeMethod<bool>('hasUsageAccess') ?? false;

  /// App launches from Android usage history since [since]: (package, time).
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

  /// Today's screen time; null without usage access.
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

  // region Android widgets
  Future<List<WidgetProvider>> widgetProviders() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'widgetProviders',
    );
    return [for (final m in raw ?? const []) WidgetProvider.fromMap(m)];
  }

  /// Starts the system flow; returns the added widget or null.
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

  // region Parking
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

  // --- Digital detox ---
  Future<void> detoxSync(Map<String, Object?> config) =>
      _methods.invokeMethod<bool>('detoxSync', config);

  Future<bool> detoxHasPin() async =>
      await _methods.invokeMethod<bool>('detoxHasPin') ?? false;

  Future<void> detoxSetPin(String pin) =>
      _methods.invokeMethod<bool>('detoxSetPin', {'pin': pin});

  /// 0 = correct, -1 = wrong, otherwise milliseconds to wait.
  Future<int> detoxCheckPin(String pin) async =>
      await _methods.invokeMethod<int>('detoxCheckPin', {'pin': pin}) ?? -1;

  Future<void> detoxPreview() => _methods.invokeMethod<bool>('detoxPreview');

  Future<bool> detoxServiceEnabled() async =>
      await _methods.invokeMethod<bool>('detoxServiceEnabled') ?? false;

  Future<bool> openDetoxService() async =>
      await _methods.invokeMethod<bool>('openDetoxService') ?? false;

  /// Installed sensitive system apps: (package, name).
  Future<List<(String, String)>> detoxSystemApps() async {
    final list = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'detoxSystemApps',
    );
    return [
      for (final m in list ?? const <Map<Object?, Object?>>[])
        (m['package'] as String, m['label'] as String),
    ];
  }

  /// Background location was denied and Android won't ask again: it must be
  /// granted from the app settings.
  Future<bool> backgroundLocationBlocked() async =>
      await _methods.invokeMethod<bool>('backgroundLocationBlocked') ?? false;

  Future<bool> requestBackgroundLocation() async =>
      await _methods.invokeMethod<bool>('requestBackgroundLocation') ?? false;
  // endregion

  // region Places
  Future<bool> hasPreciseLocation() async =>
      await _methods.invokeMethod<bool>('hasPreciseLocation') ?? false;

  Future<bool> requestPreciseLocation() async =>
      await _methods.invokeMethod<bool>('requestPreciseLocation') ?? false;

  /// Sample for places (precise location, Wi-Fi fingerprint, charging), or
  /// null without permission or data.
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

  // region Approximate location and Bluetooth
  Future<bool> hasLocation() async =>
      await _methods.invokeMethod<bool>('hasLocation') ?? false;

  Future<bool> requestLocation() async =>
      await _methods.invokeMethod<bool>('requestLocation') ?? false;

  /// Approximate location (lat, lon), or null.
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

  // region Contacts
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

  /// Opens the dialer with the number: the user starts the call.
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
  /// Media access and current track (null if nothing is playing).
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

  /// Current UTC offset of time zone [tz] (including DST).
  Future<Duration> timeZoneOffset(String tz) async => Duration(
    milliseconds:
        await _methods.invokeMethod<int>('timeZoneOffset', {'tz': tz}) ?? 0,
  );

  /// Next alarm set (by any alarm app), or null.
  Future<DateTime?> nextAlarm() async {
    final ms = await _methods.invokeMethod<int>('getNextAlarm');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<bool> openAlarms() async =>
      await _methods.invokeMethod<bool>('openAlarms') ?? false;

  /// The clock app's timers (or alarms, if the clock doesn't expose them).
  Future<bool> openTimers() async =>
      await _methods.invokeMethod<bool>('openTimers') ?? false;

  Future<bool> openDoNotDisturb() async =>
      await _methods.invokeMethod<bool>('openDoNotDisturb') ?? false;

  Future<bool> isDefaultHome() async =>
      await _methods.invokeMethod<bool>('isDefaultHome') ?? false;

  Future<bool> requestDefaultHome() async =>
      await _methods.invokeMethod<bool>('requestDefaultHome') ?? false;
}
