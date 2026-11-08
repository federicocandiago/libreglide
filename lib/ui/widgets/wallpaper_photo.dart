import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../state/wallpaper_controller.dart';
import '../scope.dart';

/// The Unsplash photo for [view], when there is one; otherwise nothing, so
/// the phone's own wallpaper shows through. In the Space it is slightly
/// blurred (if enabled), so the date and the Space name stay legible.
class WallpaperPhoto extends StatelessWidget {
  const WallpaperPhoto({
    super.key,
    required this.view,
    this.alignment = Alignment.center,
  });

  final WallpaperView view;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final wallpaper = scope.wallpaper;
    final width =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return ListenableBuilder(
      listenable: Listenable.merge([wallpaper, scope.settings]),
      builder: (context, _) {
        final file = wallpaper.fileFor(view);
        final blur =
            view == WallpaperView.space && scope.settings.spaceHeaderBlur;
        // The blur comes for free: the photo is decoded at 1/8 of the width
        // and scaled up smoothly (no filter recomputed while scrolling).
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: file == null
              ? const SizedBox.expand(key: ValueKey('none'))
              : Image.file(
                  file,
                  key: ValueKey('${file.path}|$blur'),
                  fit: BoxFit.cover,
                  alignment: alignment,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: blur ? (width / 8).round() : width,
                  filterQuality: blur
                      ? FilterQuality.medium
                      : FilterQuality.low,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
        );
      },
    );
  }
}

/// Attribution required by Unsplash ("Photo by Name · Unsplash"), with link,
/// for the photo shown in [view].
class WallpaperCredit extends StatelessWidget {
  const WallpaperCredit({super.key, required this.view});

  final WallpaperView view;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final wallpaper = scope.wallpaper;
    return ListenableBuilder(
      listenable: wallpaper,
      builder: (context, _) {
        final w = wallpaper.photoFor(view);
        if (w == null) return const SizedBox();
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
