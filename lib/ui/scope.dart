import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../state/launcher_controller.dart';
import '../state/wallpaper_controller.dart';

/// Rende controller e impostazioni disponibili a tutta la UI.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.controller,
    required this.settings,
    required this.wallpaper,
    required super.child,
  });

  final LauncherController controller;
  final SettingsController settings;
  final WallpaperController wallpaper;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope mancante');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      controller != oldWidget.controller ||
      settings != oldWidget.settings ||
      wallpaper != oldWidget.wallpaper;
}
