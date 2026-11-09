import 'package:flutter/material.dart';

import '../scope.dart';

/// With glass and the Unsplash Home photo, its blurred version sits behind
/// the page (the launcher's tabs and bar, search, contacts), so the phone's
/// own wallpaper never shows through in its place. The blur comes for free:
/// decoded at 32 px and upscaled.
class GlassPhoto extends StatelessWidget {
  const GlassPhoto({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        scope.settings.appearance,
        scope.wallpaper,
      ]),
      child: child,
      builder: (context, child) {
        final file = scope.wallpaper.file;
        if (!scope.settings.frostedGlass || file == null) return child!;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 32,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
            child!,
          ],
        );
      },
    );
  }
}
