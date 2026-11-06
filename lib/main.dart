import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/launch_store.dart';
import 'data/settings.dart';
import 'perf/frame_stats.dart';
import 'platform/launcher_bridge.dart';
import 'theme/palette.dart';
import 'theme/system_font.dart';
import 'state/launcher_controller.dart';
import 'state/wallpaper_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  appFontFamily = await loadSystemFont();
  final settings = await SettingsController.load();
  final store = await LaunchStore.open();
  final controller = LauncherController(
    bridge: LauncherBridge(),
    store: store,
    settings: settings,
  );

  // Icone renderizzate a 56dp nella densità dello schermo.
  final views = PlatformDispatcher.instance.views;
  final dpr = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
  controller.icons.sizePx = (56 * dpr).round();
  controller.cards.artSizePx = (64 * dpr).round();

  final wallpaper = WallpaperController(
    launcher: controller,
    settings: settings,
  );
  if (views.isNotEmpty) {
    // Foto alla larghezza fisica dello schermo, massimo 1440 px.
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
