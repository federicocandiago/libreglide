/// Contextual wallpaper: an Unsplash photo picked for the current moment and
/// shown only inside libreGLIDE. The system wallpaper is never touched:
/// "reverting" simply means not drawing the photo.
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

class WallpaperController extends ChangeNotifier {
  WallpaperController({
    required this.launcher,
    required this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LauncherController launcher;
  final SettingsController settings;
  final DateTime Function() _clock;

  CurrentWallpaper? current;
  WallpaperStatus status = WallpaperStatus.off;
  WallpaperMoment? moment;

  /// Width in pixels requested from Unsplash.
  int widthPx = 1440;

  bool _busy = false;
  String? _verifiedKey;
  String? _failedKey;
  DateTime? _failedAt;
  StreamSubscription<void>? _resumeSub;

  void start() {
    final saved = settings.wallpaperState;
    if (saved != null) {
      try {
        final w = CurrentWallpaper.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
        );
        if (w.file.existsSync()) current = w;
      } catch (_) {}
    }
    launcher.addListener(update);
    launcher.weather.addListener(update);
    settings.addListener(update);
    // After returning to Home the signals (time zone, headphones) refresh:
    // check again after a short delay.
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

  /// The photo is active only if the feature is on and there is a key.
  bool get active =>
      settings.contextWallpaper && (settings.unsplashKey?.isNotEmpty ?? false);

  /// File to draw, or null (= the phone's wallpaper shows through).
  File? get file => active ? current?.file : null;

  void update() {
    if (!active) {
      if (status != WallpaperStatus.off) {
        status = WallpaperStatus.off;
        notifyListeners();
      }
      return;
    }
    final now = _clock();
    final m = momentFor(
      now,
      slot: launcher.context.slot,
      travelling: launcher.travelling,
      audio: launcher.context.audio,
      weather: settings.weatherCard ? launcher.weather.weather?.kind : null,
    );
    final today = dayKey(now);
    final cacheKey = '${m.query}|$today|${settings.shuffleFor(today)}';
    moment = m;
    // Check the file once per photo, not on every update: existsSync is I/O
    // on the UI thread.
    if (current?.cacheKey == cacheKey &&
        (_verifiedKey == cacheKey || current!.file.existsSync())) {
      _verifiedKey = cacheKey;
      if (status != WallpaperStatus.idle) {
        status = WallpaperStatus.idle;
        notifyListeners();
      }
      return;
    }
    // After an error, don't retry the same search for 10 minutes.
    if (_failedKey == cacheKey &&
        _failedAt != null &&
        now.difference(_failedAt!) < const Duration(minutes: 10)) {
      return;
    }
    if (_busy) return;
    unawaited(_fetch(m, today, cacheKey));
  }

  /// "Change photo": the next one among the top results for this moment.
  void next() => settings.nextWallpaper(dayKey(_clock()));

  Future<void> _fetch(WallpaperMoment m, String today, String cacheKey) async {
    _busy = true;
    status = WallpaperStatus.loading;
    notifyListeners();
    final client = UnsplashClient(settings.unsplashKey!);
    try {
      final photos = await client.search(m.query);
      if (photos.isEmpty) throw const UnsplashException('no photos');
      final now = _clock();
      final photo =
          photos[pickIndex(
            m.query,
            now,
            photos.length,
            shuffle: settings.shuffleFor(today),
          )];
      final bytes = await client.download(photo, width: widthPx);
      final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'wallpaper'),
      );
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, '${photo.id}.jpg'));
      await file.writeAsBytes(bytes, flush: true);
      unawaited(client.trackDownload(photo));
      // Keep only the photo in use.
      await for (final f in dir.list()) {
        if (f.path != file.path) await f.delete();
      }
      current = CurrentWallpaper(
        path: file.path,
        authorName: photo.authorName,
        authorUrl: withUtm(photo.authorUrl),
        photoUrl: withUtm(photo.photoUrl),
        momentId: m.id,
        cacheKey: cacheKey,
      );
      settings.saveWallpaperState(jsonEncode(current!.toJson()));
      status = WallpaperStatus.idle;
      _failedKey = null;
    } on UnsplashException catch (e) {
      status = e.invalidKey
          ? WallpaperStatus.invalidKey
          : WallpaperStatus.error;
      _failedKey = cacheKey;
      _failedAt = _clock();
    } catch (e) {
      debugPrint('libreglide: wallpaper unavailable: $e');
      status = WallpaperStatus.error;
      _failedKey = cacheKey;
      _failedAt = _clock();
    } finally {
      client.close();
      _busy = false;
      notifyListeners();
    }
  }
}
