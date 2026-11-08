/// Unsplash wallpapers, shown only inside libreGLIDE. The system wallpaper
/// is never touched: "reverting" simply means not drawing the photo.
///
/// Two independent photos:
/// - **daily**: a new random photo the first time the launcher is used each
///   day, shown on Home (and in the Space when the contextual one is off);
/// - **contextual**: a photo that follows the moment (holiday, travel,
///   weather, music, time of day), shown only in the Space header.
///
/// Both searches include the photo style chosen in settings.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/wallpaper_moment.dart';
import '../data/settings.dart';
import '../net/unsplash.dart';
import 'launcher_controller.dart';

enum WallpaperStatus { off, idle, loading, invalidKey, error }

/// Where a photo is drawn.
enum WallpaperView { home, space }

class CurrentWallpaper {
  const CurrentWallpaper({
    required this.path,
    required this.authorName,
    required this.authorUrl,
    required this.photoUrl,
    required this.momentId,
    required this.cacheKey,
  });

  factory CurrentWallpaper.fromJson(Map<String, dynamic> j) => CurrentWallpaper(
    path: j['path'] as String,
    authorName: j['authorName'] as String,
    authorUrl: j['authorUrl'] as String,
    photoUrl: j['photoUrl'] as String,
    momentId: j['momentId'] as String,
    cacheKey: j['cacheKey'] as String,
  );

  final String path;
  final String authorName;
  final String authorUrl;
  final String photoUrl;
  final String momentId;
  final String cacheKey;

  File get file => File(path);

  Map<String, dynamic> toJson() => {
    'path': path,
    'authorName': authorName,
    'authorUrl': authorUrl,
    'photoUrl': photoUrl,
    'momentId': momentId,
    'cacheKey': cacheKey,
  };
}

/// One of the two photos: what is shown, its state and its retry guard.
class WallpaperSlot {
  WallpaperSlot._(this.dirName);

  /// Folder under the app support directory; each slot cleans only its own.
  final String dirName;

  CurrentWallpaper? current;
  WallpaperStatus status = WallpaperStatus.off;

  bool _busy = false;
  String? _verifiedKey;
  String? _failedKey;
  DateTime? _failedAt;

  void _restore(String? saved) {
    if (saved == null) return;
    try {
      final w = CurrentWallpaper.fromJson(
        jsonDecode(saved) as Map<String, dynamic>,
      );
      if (w.file.existsSync()) current = w;
    } catch (_) {}
  }

  /// Whether the photo for [cacheKey] is already on disk. The file is
  /// checked once per photo, not on every update: existsSync is I/O on the
  /// UI thread.
  bool _has(String cacheKey) {
    if (current?.cacheKey != cacheKey) return false;
    if (_verifiedKey == cacheKey || current!.file.existsSync()) {
      _verifiedKey = cacheKey;
      return true;
    }
    return false;
  }

  /// After an error, don't retry the same search for 10 minutes.
  bool _backingOff(String cacheKey, DateTime now) =>
      _failedKey == cacheKey &&
      _failedAt != null &&
      now.difference(_failedAt!) < const Duration(minutes: 10);
}

class WallpaperController extends ChangeNotifier {
  WallpaperController({
    required this.launcher,
    required this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LauncherController launcher;
  final SettingsController settings;
  final DateTime Function() _clock;

  /// The folder of the contextual photo keeps its pre-1.2 name, so the photo
  /// saved by older versions is still found.
  final daily = WallpaperSlot._('wallpaper_daily');
  final contextual = WallpaperSlot._('wallpaper');

  /// Current moment of the contextual photo (shown in settings).
  WallpaperMoment? moment;

  /// Width in pixels requested from Unsplash.
  int widthPx = 1440;

  StreamSubscription<void>? _resumeSub;

  void start() {
    daily._restore(settings.dailyWallpaperState);
    contextual._restore(settings.wallpaperState);
    launcher.addListener(update);
    launcher.weather.addListener(update);
    settings.addListener(update);
    // After returning to Home the signals (time zone, headphones) refresh:
    // check again after a short delay. This is also where a new day's
    // first visit fetches the new daily photo.
    _resumeSub = launcher.bridge.resumed.listen(
      (_) => Future<void>.delayed(const Duration(milliseconds: 600), update),
    );
    update();
  }

  @override
  void dispose() {
    launcher.removeListener(update);
    launcher.weather.removeListener(update);
    settings.removeListener(update);
    _resumeSub?.cancel();
    super.dispose();
  }

  static String dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  bool get _hasKey => settings.unsplashKey?.isNotEmpty ?? false;

  /// Daily photo on: feature enabled and a key entered.
  bool get dailyActive => settings.dailyWallpaper && _hasKey;

  /// Contextual photo on: feature enabled and a key entered.
  bool get contextActive => settings.contextWallpaper && _hasKey;

  /// The photo drawn in [view], or null (= the phone's wallpaper shows
  /// through). The Space prefers the contextual photo and falls back to the
  /// daily one, so Home and Space stay consistent.
  CurrentWallpaper? photoFor(WallpaperView view) {
    final d = dailyActive ? daily.current : null;
    if (view == WallpaperView.home) return d;
    return (contextActive ? contextual.current : null) ?? d;
  }

  /// File to draw in [view], or null.
  File? fileFor(WallpaperView view) => photoFor(view)?.file;

  /// The photo behind the frosted-glass pages: the Home one.
  File? get file => fileFor(WallpaperView.home);

  void update() {
    final now = _clock();
    final today = dayKey(now);
    final style = settings.wallpaperStyle;

    if (_setOff(daily, !dailyActive) | _setOff(contextual, !contextActive)) {
      notifyListeners();
    }

    if (dailyActive) {
      final query = dailyQuery(style);
      final cacheKey = 'daily|$query|$today|${settings.dailyShuffleFor(today)}';
      _ensure(daily, cacheKey, now, () => _fetchDaily(query, cacheKey));
    }

    if (contextActive) {
      final m = momentFor(
        now,
        slot: launcher.context.slot,
        travelling: launcher.travelling,
        audio: launcher.context.audio,
        weather: settings.weatherCard ? launcher.weather.weather?.kind : null,
      );
      moment = m;
      final query = withStyle(m.query, style);
      final cacheKey = '$query|$today|${settings.shuffleFor(today)}';
      _ensure(
        contextual,
        cacheKey,
        now,
        () => _fetchContextual(m, query, today, cacheKey),
      );
    }
  }

  /// Marks [slot] off when [off]; returns whether its status changed.
  bool _setOff(WallpaperSlot slot, bool off) {
    if (!off || slot.status == WallpaperStatus.off) return false;
    slot.status = WallpaperStatus.off;
    return true;
  }

  /// Starts [fetch] unless the photo for [cacheKey] is already there, a
  /// download is running, or the same search failed a moment ago. The old
  /// photo stays on screen until the new one is ready (or if offline).
  void _ensure(
    WallpaperSlot slot,
    String cacheKey,
    DateTime now,
    Future<void> Function() fetch,
  ) {
    if (slot._has(cacheKey)) {
      if (slot.status != WallpaperStatus.idle) {
        slot.status = WallpaperStatus.idle;
        notifyListeners();
      }
      return;
    }
    if (slot._busy || slot._backingOff(cacheKey, now)) return;
    unawaited(fetch());
  }

  /// "Change today's photo" (daily).
  void nextDaily() => settings.nextDailyWallpaper(dayKey(_clock()));

  /// "Change photo" (contextual): the next one among the top results for
  /// this moment.
  void next() => settings.nextWallpaper(dayKey(_clock()));

  Future<void> _fetchDaily(String query, String cacheKey) => _download(
    daily,
    cacheKey,
    momentId: 'daily',
    pick: (client) => client.random(query),
    save: settings.saveDailyWallpaperState,
  );

  Future<void> _fetchContextual(
    WallpaperMoment m,
    String query,
    String today,
    String cacheKey,
  ) => _download(
    contextual,
    cacheKey,
    momentId: m.id,
    pick: (client) async {
      var photos = await client.search(query);
      // A style word can narrow the search too much: fall back to the
      // moment alone.
      if (photos.length < 3 && query != m.query) {
        photos = await client.search(m.query);
      }
      if (photos.isEmpty) throw const UnsplashException('no photos');
      return photos[pickIndex(
        query,
        _clock(),
        photos.length,
        shuffle: settings.shuffleFor(today),
      )];
    },
    save: settings.saveWallpaperState,
  );

  /// Picks a photo with [pick], downloads it into the slot's folder, removes
  /// the slot's previous file and saves the state with [save].
  Future<void> _download(
    WallpaperSlot slot,
    String cacheKey, {
    required String momentId,
    required Future<UnsplashPhoto> Function(UnsplashClient client) pick,
    required void Function(String json) save,
  }) async {
    slot._busy = true;
    slot.status = WallpaperStatus.loading;
    notifyListeners();
    final client = UnsplashClient(settings.unsplashKey!);
    try {
      final photo = await pick(client);
      final bytes = await client.download(photo, width: widthPx);
      final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, slot.dirName),
      );
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, '${photo.id}.jpg'));
      await file.writeAsBytes(bytes, flush: true);
      unawaited(client.trackDownload(photo));
      // Keep only the photo in use (files only: never touch other folders).
      await for (final f in dir.list()) {
        if (f is File && f.path != file.path) await f.delete();
      }
      slot.current = CurrentWallpaper(
        path: file.path,
        authorName: photo.authorName,
        authorUrl: withUtm(photo.authorUrl),
        photoUrl: withUtm(photo.photoUrl),
        momentId: momentId,
        cacheKey: cacheKey,
      );
      slot._verifiedKey = cacheKey;
      save(jsonEncode(slot.current!.toJson()));
      slot.status = WallpaperStatus.idle;
      slot._failedKey = null;
    } on UnsplashException catch (e) {
      slot.status = e.invalidKey
          ? WallpaperStatus.invalidKey
          : WallpaperStatus.error;
      slot._failedKey = cacheKey;
      slot._failedAt = _clock();
    } catch (e) {
      debugPrint('libreglide: wallpaper unavailable: $e');
      slot.status = WallpaperStatus.error;
      slot._failedKey = cacheKey;
      slot._failedAt = _clock();
    } finally {
      client.close();
      slot._busy = false;
      notifyListeners();
    }
  }
}
