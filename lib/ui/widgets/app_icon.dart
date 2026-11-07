import 'package:flutter/material.dart';

import '../../core/app_entry.dart';
import '../glide_style.dart';
import '../scope.dart';
import 'app_actions.dart';

/// App icon: original, themed (monochrome layer) or placeholder.
class AppIconView extends StatelessWidget {
  const AppIconView({super.key, required this.app, this.size = 52});

  final AppEntry app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cache = scope.controller.icons;
    final scheme = Theme.of(context).colorScheme;
    // Decode at the displayed size, not the PNG's native size.
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return ListenableBuilder(
      listenable: Listenable.merge([cache, scope.settings.appearance]),
      builder: (context, _) {
        final icon = cache[app.id];
        final themed = scope.settings.themedIcons;
        Widget child;
        if (icon == null) {
          child = _Placeholder(app: app, size: size);
        } else if (themed && icon.mono != null) {
          child = Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Image.memory(
              icon.mono!,
              width: size,
              height: size,
              color: scheme.onPrimaryContainer,
              colorBlendMode: BlendMode.srcIn,
              cacheWidth: decodeSize,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          );
        } else {
          child = Image.memory(
            icon.icon,
            width: size,
            height: size,
            cacheWidth: decodeSize,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(icon == null ? 'p' : (themed ? 't' : 'i')),
            child: child,
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.app, required this.size});

  final AppEntry app;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = app.label.isEmpty ? '?' : app.label.characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The widget's rectangle in physical pixels, for the launch animation.
List<int>? boundsOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final topLeft = box.localToGlobal(Offset.zero) * dpr;
  final bottomRight =
      box.localToGlobal(box.size.bottomRight(Offset.zero)) * dpr;
  return [
    topLeft.dx.round(),
    topLeft.dy.round(),
    bottomRight.dx.round(),
    bottomRight.dy.round(),
  ];
}

/// Icon with label: tap to open, long press for actions.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.app,
    this.iconSize = 52,
    this.showLabel = true,
    this.labelLines = 1,
  });

  final AppEntry app;
  final double iconSize;
  final bool showLabel;

  /// Label lines (2 in the A-Z grid, as in Glide).
  final int labelLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: theme.colorScheme.onSurface,
    );

    return Semantics(
      button: true,
      label: app.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () => launchFrom(context, app),
        onLongPress: () => showAppActions(context, app),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconView(app: app, size: iconSize),
              if (showLabel) ...[
                const SizedBox(height: 6),
                Text(
                  app.label,
                  // A single word must not wrap mid-word: keep it on one line.
                  maxLines: app.label.trim().contains(' ') ? labelLines : 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: maxLabelScale),
                  style: labelStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the app, animating the launch from the widget of [context].
void launchFrom(BuildContext context, AppEntry app) {
  AppScope.of(context).controller.launch(app, bounds: boundsOf(context));
}
