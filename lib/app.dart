import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'data/settings.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/launcher_controller.dart';
import 'state/wallpaper_controller.dart';
import 'theme/palette.dart';
import 'ui/scope.dart';
import 'ui/shell.dart';

class LibreGlideApp extends StatelessWidget {
  const LibreGlideApp({
    super.key,
    required this.controller,
    required this.settings,
    required this.wallpaper,
  });

  final LauncherController controller;
  final SettingsController settings;
  final WallpaperController wallpaper;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      settings: settings,
      wallpaper: wallpaper,
      child: DynamicColorBuilder(
        // Solo l'aspetto ricostruisce l'app: preferiti, widget, card e così
        // via aggiornano soltanto le parti che li usano.
        builder: (lightDynamic, darkDynamic) => ListenableBuilder(
          listenable: settings.appearance,
          builder: (context, _) => MaterialApp(
            title: 'libreGLIDE',
            debugShowCheckedModeBanner: false,
            color: Colors.transparent,
            theme: themeFor(
              settings: settings,
              brightness: Brightness.light,
              systemScheme: lightDynamic,
            ),
            darkTheme: themeFor(
              settings: settings,
              brightness: Brightness.dark,
              systemScheme: darkDynamic,
            ),
            themeMode: settings.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 300),
            locale: settings.locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: L10n.localizationsDelegates,
            home: const LauncherShell(),
          ),
        ),
      ),
    );
  }
}
