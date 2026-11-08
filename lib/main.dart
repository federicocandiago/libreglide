import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_info.dart';
import 'data/launch_store.dart';
import 'data/settings.dart';
import 'perf/frame_stats.dart';
import 'platform/launcher_bridge.dart';
import 'platform/orientation.dart';
import 'theme/palette.dart';
import 'theme/system_font.dart';
import 'state/launcher_controller.dart';
import 'state/wallpaper_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await loadAppInfo();
  appFontFamily = await loadSystemFont();
  final settings = await SettingsController.load();
  await applyOrientation(lockPortrait: settings.lockPortrait);
  var lockPortrait = settings.lockPortrait;
  settings.addListener(() {
    if (settings.lockPortrait == lockPortrait) return;
    lockPortrait = settings.lockPortrait;
    applyOrientation(lockPortrait: lockPortrait);
  });
  final store = await LaunchStore.open();
  final controller = LauncherController(
    bridge: LauncherBridge(),
    store: store,
    settings: settings,
  );

  // Icons rendered at 56dp in the screen's pixel density.
  final views = PlatformDispatcher.instance.views;
  final dpr = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
  controller.icons.sizePx = (56 * dpr).round();
  controller.cards.artSizePx = (64 * dpr).round();

  final wallpaper = WallpaperController(
    launcher: controller,
    settings: settings,
  );
  if (views.isNotEmpty) {
    // Photos at the screen's physical width, at most 1440 px.
    wallpaper.widthPx = views.first.physicalSize.width.round().clamp(720, 1440);
  }

  runApp(
    LibreGlideApp(
      controller: controller,
      settings: settings,
      wallpaper: wallpaper,
    ),
  );
  FrameStats.start();
  await controller.init();
  wallpaper.start();
}
