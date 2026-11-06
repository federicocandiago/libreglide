import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../scope.dart';

/// Foto dello sfondo contestuale, se attiva; altrimenti niente, e dietro si
/// vede lo sfondo del telefono.
class ContextWallpaper extends StatelessWidget {
  const ContextWallpaper({super.key, this.alignment = Alignment.center});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final wallpaper = AppScope.of(context).wallpaper;
    final width =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return ListenableBuilder(
      listenable: wallpaper,
      builder: (context, _) {
        final file = wallpaper.file;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: file == null
              ? const SizedBox.expand(key: ValueKey('none'))
              : Image.file(
                  file,
                  key: ValueKey(file.path),
                  fit: BoxFit.cover,
                  alignment: alignment,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: width,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
        );
      },
    );
  }
}

/// Credito richiesto da Unsplash: "Foto di Nome · Unsplash", con link.
class WallpaperCredit extends StatelessWidget {
  const WallpaperCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final wallpaper = scope.wallpaper;
    return ListenableBuilder(
      listenable: wallpaper,
      builder: (context, _) {
        final w = wallpaper.current;
        if (wallpaper.file == null || w == null) return const SizedBox();
        const shadow = [Shadow(blurRadius: 6, color: Colors.black87)];
        return GestureDetector(
          onTap: () => scope.controller.bridge.openUrl(w.photoUrl),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              L10n.of(context).photoBy(w.authorName),
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                shadows: shadow,
              ),
            ),
          ),
        );
      },
    );
  }
}
