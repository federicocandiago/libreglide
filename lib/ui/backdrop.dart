/// Frosted-glass backdrop: the Unsplash Home photo painted once, below the
/// Navigator, under every page and every route (spec-viste-app §6.4).
///
/// With glass on and a Home photo, the pages no longer carry their own
/// photo: they are translucent over this backdrop, which stays still while
/// the content moves. The photo gets blurrier, with an ease, the farther the
/// page is from Home (Space and Collections one step, A-Z two), and is
/// blurriest under global search and contacts. Since it sits below every
/// route, no transition (pages, search, contacts, the drawer) can ever show
/// the phone's own wallpaper in its place.
///
/// The page tint is part of the backdrop too: still, and fading in with the
/// same ease as the blur, so moving from Home to a side page is one
/// continuum (pages are transparent over it; only their cards move).
///
/// The look is frosted ice rather than fog: a moderate blur (shapes still
/// show), slightly richer colors, a fairly opaque light tint and a fine
/// grain.
///
/// The blur is not recomputed while scrolling: the photo is rendered once at
/// a few levels (sharp, then [_blurSigmas]) and the painter cross-fades the
/// two levels around the current value.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'glide_style.dart';
import 'scope.dart';

/// Blur (sigma) of each level after the sharp one, as a fraction of the
/// screen width: about 11, 24 and 49 px on a 1080 px screen (the last one
/// under search and contacts).
const List<double> _blurSigmas = [0.010, 0.022, 0.045];

/// Saturation of the blurred levels (1 = unchanged): frosted ice lets color
/// through, fog washes it out.
const double _saturation = 1.25;

/// Opacity of the grain at full tint.
const double _grainOpacity = 0.09;

/// The tint over the photo, fully in from one page away from Home: light
/// and fairly opaque, like frosted ice.
Color iceTint(ColorScheme scheme) => scheme.brightness == Brightness.dark
    ? scheme.surfaceContainer.withValues(alpha: 0.6)
    : Color.alphaBlend(
        Colors.white.withValues(alpha: 0.35),
        scheme.surfaceContainerHigh,
      ).withValues(alpha: 0.62);

/// How much of the launcher shows under a route open by [away]: gone by
/// about 60%, so the route never sits on a half-visible launcher.
double underRouteOpacity(double away) => (1 - away * 1.6).clamp(0.0, 1.0);

ColorFilter _saturate(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final k = 1 - s;
  return ColorFilter.matrix([
    r * k + s, g * k, b * k, 0, 0, //
    r * k, g * k + s, b * k, 0, 0, //
    r * k, g * k, b * k + s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

/// Highest blur level (under search and contacts).
const double maxBackdropLevel = 3;

/// Highest level reached by swiping between pages.
const double maxPageLevel = 2;

/// The blur level for the pager at [page], with Home at [home]: one level
/// per page of distance, eased within each step.
double pageBackdropLevel(double page, int home) {
  final d = (page - home).abs().clamp(0.0, maxPageLevel);
  final step = d.floorToDouble();
  return step + Curves.easeInOut.transform(d - step);
}

/// The blur level shown for a page at [pageLevel] while a route covers it by
/// [away] (0 = no route, 1 = route fully open).
double backdropLevel(double pageLevel, double away) =>
    pageLevel + (maxBackdropLevel - pageLevel) * away.clamp(0.0, 1.0);

/// Where the backdrop stands: the pager's level and how much a backdrop
/// route (search, contacts) covers it.
class BackdropMotion extends ChangeNotifier {
  double _page = 0;
  double _away = 0;

  /// Level from the pager (see [pageBackdropLevel]).
  double get page => _page;
  set page(double v) {
    if (v == _page) return;
    _page = v;
    notifyListeners();
  }

  /// How much a [BackdropRoute] covers the pages, eased (0…1).
  double get away => _away;
  set away(double v) {
    if (v == _away) return;
    _away = v;
    notifyListeners();
  }

  /// The blur level to paint (0 = sharp … [maxBackdropLevel]).
  double get level => backdropLevel(_page, _away);
}

/// Paints the backdrop below [child] (the Navigator: put it in
/// `MaterialApp.builder`).
class LauncherBackdrop extends StatefulWidget {
  const LauncherBackdrop({super.key, required this.child});

  final Widget child;

  /// The shared motion (the shell drives the page level, routes the rest).
  static BackdropMotion motionOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackdropScope>()!.motion;

  /// Whether the backdrop is on (glass and a Home photo): pages and routes
  /// are then translucent over it. Rebuilds [context] when it changes.
  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BackdropScope>()?.active ??
      false;

  /// Like [activeOf], without depending on it (for routes and callbacks).
  static bool readActive(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackdropScope>()?.active ?? false;

  @override
  State<LauncherBackdrop> createState() => _LauncherBackdropState();
}

class _LauncherBackdropState extends State<LauncherBackdrop>
    with SingleTickerProviderStateMixin {
  final _motion = BackdropMotion();
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    value: 1,
  );

  Listenable? _sources;

  /// The photo being shown (or loading) and the size it was rendered for.
  String? _path;
  Size? _renderedFor;
  int _generation = 0;

  _Layers? _layers;

  /// The previous photo, fading out.
  _Layers? _old;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sources == null) {
      final scope = AppScope.of(context);
      _sources = Listenable.merge([scope.settings.appearance, scope.wallpaper])
        ..addListener(_sync);
    }
    _sync();
  }

  @override
  void dispose() {
    _sources?.removeListener(_sync);
    _fade.dispose();
    _motion.dispose();
    _layers?.dispose();
    _old?.dispose();
    super.dispose();
  }

  bool get _wanted {
    final scope = AppScope.of(context);
    return scope.settings.frostedGlass && scope.wallpaper.file != null;
  }

  void _sync() {
    if (!mounted) return;
    final scope = AppScope.of(context);
    final path = _wanted ? scope.wallpaper.file!.path : null;
    final media = MediaQuery.of(context);
    final size = media.size * media.devicePixelRatio;
    if (path == _path && (path == null || size == _renderedFor)) {
      setState(() {}); // `active` may have changed
      return;
    }
    _path = path;
    final generation = ++_generation;
    if (path == null) {
      _drop();
      return;
    }
    if (size.isEmpty) return;
    _renderedFor = size;
    _Layers.render(File(path), size).then((layers) {
      if (!mounted || generation != _generation) {
        layers?.dispose();
        return;
      }
      if (layers == null) {
        _drop();
        return;
      }
      setState(() {
        _old?.dispose();
        _old = _layers;
        _layers = layers;
      });
      _fade.forward(from: _old == null ? 1 : 0).whenComplete(_dropOld);
    });
  }

  /// No photo: stop painting, then free the images (never while a painter
  /// still holds them).
  void _drop() {
    final gone = [?_layers, ?_old];
    setState(() {
      _layers = null;
      _old = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final l in gone) {
        l.dispose();
      }
    });
  }

  void _dropOld() {
    final old = _old;
    if (old == null || !mounted || _fade.value < 1) return;
    setState(() => _old = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final active = _path != null;
    return _BackdropScope(
      motion: _motion,
      active: active,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (active)
            IgnorePointer(
              child: CustomPaint(
                painter: _BackdropPainter(
                  layers: _layers,
                  old: _old,
                  motion: _motion,
                  fade: _fade,
                  tint: iceTint(Theme.of(context).colorScheme),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _BackdropScope extends InheritedWidget {
  const _BackdropScope({
    required this.motion,
    required this.active,
    required super.child,
  });

  final BackdropMotion motion;
  final bool active;

  @override
  bool updateShouldNotify(_BackdropScope old) => old.active != active;
}

/// The photo rendered at every level: sharp at screen size, then blurred on
/// a reduced copy (blurring hides the lower resolution, so there are no
/// visible pixels when it is scaled up).
class _Layers {
  _Layers(this.images, this.grain);

  final List<ui.Image> images;

  /// Fine neutral-grey noise, tiled over the tint.
  final ui.Image grain;

  void dispose() {
    for (final i in images) {
      i.dispose();
    }
    grain.dispose();
  }

  static Future<ui.Image> _grain() {
    const n = 128;
    final rnd = math.Random(7);
    final px = Uint8List(n * n * 4);
    for (var i = 0; i < px.length; i += 4) {
      final v = (128 + (rnd.nextDouble() - 0.5) * 90).round();
      px[i] = px[i + 1] = px[i + 2] = v;
      px[i + 3] = 255;
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(px, n, n, ui.PixelFormat.rgba8888, done.complete);
    return done.future;
  }

  static Future<_Layers?> render(File file, Size screen) async {
    try {
      final bytes = await file.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      // Decoded just large enough to cover the screen (never upscaled).
      final cover = math.max(
        screen.width / descriptor.width,
        screen.height / descriptor.height,
      );
      final scale = math.min(1.0, cover);
      final codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      final sharp = (await codec.getNextFrame()).image;
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();

      final small = await _draw(
        (sharp.width / 4).round().clamp(1, sharp.width),
        (sharp.height / 4).round().clamp(1, sharp.height),
        (canvas, w, h) => canvas.drawImageRect(
          sharp,
          Offset.zero & Size(sharp.width.toDouble(), sharp.height.toDouble()),
          Offset.zero & Size(w.toDouble(), h.toDouble()),
          Paint()..filterQuality = FilterQuality.medium,
        ),
      );
      // Sigma in the reduced photo's pixels for a blur of f × screen width
      // on screen (the sharp photo is shown scaled by `shown`).
      final shown = math.max(
        screen.width / sharp.width,
        screen.height / sharp.height,
      );
      final toSmall = small.width / sharp.width / shown;
      final blurred = <ui.Image>[];
      for (final f in _blurSigmas) {
        final sigma = f * screen.width * toSmall;
        blurred.add(
          await _draw(
            small.width,
            small.height,
            (canvas, _, _) => canvas.drawImage(
              small,
              Offset.zero,
              Paint()
                ..colorFilter = _saturate(_saturation)
                ..imageFilter = ui.ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.clamp,
                ),
            ),
          ),
        );
      }
      small.dispose();
      return _Layers([sharp, ...blurred], await _grain());
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _draw(
    int w,
    int h,
    void Function(Canvas canvas, int w, int h) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), w, h);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    return image;
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.layers,
    required this.old,
    required this.motion,
    required this.fade,
    required this.tint,
  }) : super(repaint: Listenable.merge([motion, fade]));

  /// Null while the photo is still being prepared (only the tint shows).
  final _Layers? layers;
  final _Layers? old;
  final BackdropMotion motion;
  final Animation<double> fade;

  /// The pages' tint, fully in from one page away from Home.
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void paintSet(_Layers set, double opacity) {
      if (opacity <= 0) return;
      final top = set.images.length - 1;
      final v = motion.level.clamp(0.0, top.toDouble());
      final i = v.floor();
      final f = v - i;
      void draw(ui.Image image, double o) => paintImage(
        canvas: canvas,
        rect: rect,
        image: image,
        fit: BoxFit.cover,
        opacity: o,
        filterQuality: FilterQuality.medium,
      );
      draw(set.images[i], opacity);
      if (f > 0.001 && i < top) draw(set.images[i + 1], opacity * f);
    }

    final previous = old;
    if (previous != null && fade.value < 1) paintSet(previous, 1);
    final current = layers;
    if (current != null) paintSet(current, previous == null ? 1 : fade.value);

    final t = motion.level.clamp(0.0, 1.0);
    if (t > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = tint.withValues(alpha: tint.a * t),
      );
      final grain = (current ?? previous)?.grain;
      if (grain != null) {
        // Neutral grey with "overlay": it only adds texture. Each grain is
        // 2 physical pixels.
        final dpr =
            ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
        canvas.drawRect(
          rect,
          Paint()
            ..shader = ImageShader(
              grain,
              TileMode.repeated,
              TileMode.repeated,
              Matrix4.diagonal3Values(2 / dpr, 2 / dpr, 1).storage,
            )
            ..blendMode = BlendMode.overlay
            ..color = Colors.black.withValues(alpha: _grainOpacity * t),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.layers != layers || old.old != this.old || old.tint != tint;
}

/// Search and contacts open in sequence: first the ice starts forming and
/// the launcher fades away, then, from about a third of the way, the panels
/// fade in, sliding by [fromY] (a fraction of the height). Closing runs the
/// same steps backwards.
RouteTransitionsBuilder panelTransition(double fromY) =>
    (context, animation, _, child) {
      final panels = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
        reverseCurve: const Interval(0.35, 1, curve: Curves.easeInCubic),
      );
      return FadeTransition(
        opacity: panels,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, fromY),
            end: Offset.zero,
          ).animate(panels),
          child: child,
        ),
      );
    };

/// Durations of the search and contacts transitions.
const panelOpenDuration = Duration(milliseconds: 400);
const panelCloseDuration = Duration(milliseconds: 300);

/// A full-screen route (search, contacts) over the backdrop: with the
/// backdrop on it is translucent (glass) and the backdrop blurs to the
/// highest level as it opens; otherwise an ordinary opaque route.
class BackdropRoute<T> extends PageRouteBuilder<T> {
  BackdropRoute({
    required BuildContext context,
    required super.pageBuilder,
    required super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
  }) : _motion = LauncherBackdrop.motionOf(context),
       _active = LauncherBackdrop.readActive(context),
       super(opaque: !LauncherBackdrop.readActive(context));

  final BackdropMotion _motion;
  final bool _active;

  @override
  void install() {
    super.install();
    // The controller, not [animation]: on the push frame the route is built
    // offstage (for Hero measurements) and [animation] then reads 1, which
    // flashed the full ice for one frame before the transition.
    if (_active) controller!.addListener(_sync);
  }

  void _sync() {
    _motion.away = Curves.easeInOut.transform(controller!.value);
  }

  @override
  void dispose() {
    if (_active) {
      controller?.removeListener(_sync);
      _motion.away = 0;
    }
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final page = super.buildPage(context, animation, secondaryAnimation);
    return _active ? Glass(level: 1, onBackdrop: true, child: page) : page;
  }
}

/// The launcher's content under a [BackdropRoute]: it fades out while the
/// route opens, so only the backdrop stays behind the translucent route.
class FadeUnderRoute extends StatelessWidget {
  const FadeUnderRoute({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = LauncherBackdrop.motionOf(context);
    final active = LauncherBackdrop.activeOf(context);
    return ListenableBuilder(
      listenable: motion,
      child: child,
      // Always the same Opacity, so the subtree keeps its state.
      builder: (context, child) => Opacity(
        opacity: active ? underRouteOpacity(motion.away) : 1,
        child: child,
      ),
    );
  }
}
