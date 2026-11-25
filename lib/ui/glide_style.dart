/// libreGLIDE's visual language: Glide's layout (flat bars and cards, spaced
/// small caps, thin type, a color per Space) with small Material You touches
/// (dynamic accent, tinted greys, Space colors harmonized with the palette,
/// 12 dp corners).
library;

import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/space.dart';
import '../core/time_context.dart';

/// Shared language (v0.4): Glide layout, Android 17 shapes and tones.
///
/// - borderless cards, set apart by the page tone;
/// - corners: 24 cards, 28 sheets and dialogs, 16 inner elements, pill for
///   search fields and buttons;
/// - spacing: 10 between cards and from the edges, 16 inside cards.
const double cardRadius = 24;

/// Radius of elements inside cards (boxes, choices, square icons).
const double innerRadius = 16;

/// Radius of bottom sheets and dialogs.
const double sheetRadius = 28;

/// Horizontal inner padding of cards.
const double cardPadding = 16;

/// Gap between cards and from the edges.
const double cardGap = 10;

/// Height of the tab bar.
const double tabBarHeight = 56;

/// Maximum text scale for icon labels, as in the Pixel Launcher: with large
/// system fonts labels stay readable without being fully truncated.
const double maxLabelScale = 1.15;

/// Enables frosted glass for the pages below this widget: backgrounds and
/// cards become translucent over the blurred wallpaper.
class Glass extends InheritedWidget {
  const Glass({
    super.key,
    required this.level,
    this.onBackdrop = false,
    required super.child,
  });

  /// 0 = off, 1 = blur active, 2 = blur unavailable (battery saver): nearly
  /// opaque backgrounds, to stay readable.
  final int level;

  /// Over the launcher backdrop (backdrop.dart): the backdrop paints the
  /// page tint itself, still and fading in with the blur, so page
  /// backgrounds are transparent and only the content moves.
  final bool onBackdrop;

  @override
  bool updateShouldNotify(Glass old) =>
      old.level != level || old.onBackdrop != onBackdrop;
}

class GlideColors {
  const GlideColors._(this.scheme, this._glass, this.onBackdrop);

  factory GlideColors.of(BuildContext context) {
    final glass = context.dependOnInheritedWidgetOfExactType<Glass>();
    return GlideColors._(
      Theme.of(context).colorScheme,
      glass?.level ?? 0,
      glass?.onBackdrop ?? false,
    );
  }

  final ColorScheme scheme;
  final int _glass;

  /// Pages sit over the launcher backdrop, which paints their tint.
  final bool onBackdrop;

  bool get _dark => scheme.brightness == Brightness.dark;

  /// Page background (Glide's light grey, tinted by the palette).
  /// Transparent over the backdrop, which paints it (see [glassPage]).
  Color get page {
    if (onBackdrop) return Colors.transparent;
    final base = _dark ? scheme.surface : scheme.surfaceContainerHigh;
    return switch (_glass) {
      1 => glassPage(scheme),
      2 => base.withValues(alpha: 0.9),
      _ => base,
    };
  }

  /// Translucent page tint with glass on.
  static Color glassPage(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final base = dark ? scheme.surface : scheme.surfaceContainerHigh;
    return base.withValues(alpha: dark ? 0.45 : 0.5);
  }

  /// Cards and bars (Glide's "white", slightly tinted, so icons with a white
  /// background stay recognizable in the light theme too).
  Color get card => glassCard(scheme, _glass);

  /// Card color for a given glass level (0 = opaque).
  static Color glassCard(ColorScheme scheme, int glass) {
    final dark = scheme.brightness == Brightness.dark;
    final base = dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLow;
    return switch (glass) {
      1 => base.withValues(alpha: dark ? 0.72 : 0.78),
      2 => base.withValues(alpha: 0.96),
      _ => base,
    };
  }

  /// Raised elements inside cards or over the page (search fields,
  /// unselected choices).
  Color get raised =>
      _dark ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh;

  /// Thin lines between a card's rows (cards have no border).
  Color get hairline =>
      scheme.outlineVariant.withValues(alpha: _dark ? 0.35 : 0.6);

  /// Secondary text and small caps.
  Color get muted => scheme.onSurfaceVariant;

  /// Accent: A-Z letters, indicator, banners.
  Color get accent => scheme.primary;

  /// Spaces drawer: almost black, slightly tinted.
  Color get drawer => Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.06),
    const Color(0xFF101010),
  );

  /// Color of a Space, harmonized with the current palette.
  Color space(Slot slot) => spaceBaseColor(slot).harmonizeWith(scheme.primary);

  /// Color of a Space (context or time-of-day), harmonized.
  Color spaceKind(SpaceKind k) => switch (k) {
    SpaceKind.home => const Color(0xFFF28C38),
    SpaceKind.work => const Color(0xFF3B7DD8),
    SpaceKind.moving => const Color(0xFF43A047),
    SpaceKind.listening => const Color(0xFFE0533D),
    SpaceKind.nightOut => const Color(0xFFC2185B),
    SpaceKind.exercise => const Color(0xFF00A3BF),
    SpaceKind.travel => const Color(0xFF26A69A),
    _ => spaceBaseColor(k.slot!),
  }.harmonizeWith(scheme.primary);
}

/// Base colors of the Spaces (each has its own, as in Glide).
Color spaceBaseColor(Slot slot) => switch (slot) {
  Slot.wakeUp => const Color(0xFFF5A623),
  Slot.morning => const Color(0xFFF2C12E),
  Slot.lunch => const Color(0xFFF26B3A),
  Slot.afternoon => const Color(0xFF3BAF6A),
  Slot.evening => const Color(0xFF6A5ACD),
  Slot.night => const Color(0xFF2F4F9F),
};

/// Spaced small caps for headers ("SOCIAL", "A-Z APPS").
TextStyle capsStyle(BuildContext context, {Color? color, double size = 12.5}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: color ?? GlideColors.of(context).muted,
    );

/// Thin uppercase title (Space name in the colored strip).
TextStyle thinTitleStyle({required Color color, double size = 24}) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w300,
  letterSpacing: 1.2,
  color: color,
);

/// Glide's flat card: card-coloured background, rounded corners, no border
/// and no shadow.
class FlatCard extends StatelessWidget {
  const FlatCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return Material(
      color: color ?? c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Card header: small grey icon, small caps, chevron.
class CapsHeader extends StatelessWidget {
  const CapsHeader({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.only(left: cardPadding, right: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: maxLabelScale),
                  style: capsStyle(context),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin ∨ chevron that rotates when the card is expanded.
class Chevron extends StatelessWidget {
  const Chevron({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? 0.5 : 0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    child: Icon(
      Icons.keyboard_arrow_down_rounded,
      size: 26,
      color: GlideColors.of(context).muted.withValues(alpha: 0.6),
    ),
  );
}

/// Pill-shaped search bar (Android 17 style), for search and contacts.
class PillSearchField extends StatefulWidget {
  const PillSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmitted,
    this.onClose,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  /// Called when X is tapped with an empty field (usually closes the page).
  final VoidCallback? onClose;

  @override
  State<PillSearchField> createState() => _PillSearchFieldState();
}

class _PillSearchFieldState extends State<PillSearchField>
    with WidgetsBindingObserver {
  final _focus = FocusNode();
  Animation<double>? _route;

  // Autofocus alone sometimes doesn't open the keyboard: Android ignores the
  // request if it comes while the window has no focus (just back from an
  // app, the shade closing, the page still animating in), and nothing asks
  // again. So, after the transition, the keyboard is requested explicitly:
  // once the window has focus, and again a few times until it shows.

  /// Explicit requests left, [_retryDelay] apart.
  int _attempts = 4;
  static const _retryDelay = Duration(milliseconds: 250);
  Timer? _retry;

  /// Waiting for the window to get focus before asking.
  bool _waitingWindow = false;

  /// The keyboard showed up, or the user moved focus away: stop asking.
  bool _done = false;
  bool _hadFocus = false;

  @override
  void initState() {
    super.initState();
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addObserver(this);
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autofocus) return;
    if (MediaQuery.viewInsetsOf(context).bottom > 0) _stop();
    if (_route != null) return;
    _route = ModalRoute.of(context)?.animation;
    if (_route == null || _route!.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showKeyboard());
    } else {
      _route!.addStatusListener(_onRoute);
    }
  }

  void _onRoute(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _route?.removeStatusListener(_onRoute);
    _showKeyboard();
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _hadFocus = true;
    } else if (_hadFocus) {
      _stop(); // the user dismissed it (scrolling, a tap elsewhere)
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingWindow) {
      _waitingWindow = false;
      _showKeyboard();
    }
  }

  void _stop() {
    _done = true;
    _waitingWindow = false;
    _retry?.cancel();
  }

  void _showKeyboard() {
    if (!mounted || _done) return;
    // "resumed" means the window has focus (the engine reports Android's
    // window focus): before that, the request would be dropped.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _waitingWindow = true;
      return;
    }
    if (!_focus.hasFocus) _focus.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    _retry?.cancel();
    if (--_attempts > 0) _retry = Timer(_retryDelay, _showKeyboard);
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRoute);
    _retry?.cancel();
    if (widget.autofocus) WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = GlideColors.of(context);
    final controller = widget.controller;
    return Material(
      color: c.card,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(Icons.search_rounded, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                textInputAction: TextInputAction.go,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onSubmitted: (_) => widget.onSubmitted?.call(),
              ),
            ),
            IconButton(
              color: c.muted,
              onPressed: () => controller.text.isEmpty
                  ? widget.onClose?.call()
                  : controller.clear(),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Opaque color of the tab bar and dock tray (even with glass enabled: they
/// stay opaque on Home).
Color solidBarColor(BuildContext context) =>
    GlideColors.glassCard(Theme.of(context).colorScheme, 0);

/// Slightly rounded corners of the "window" over the Home wallpaper: corner
/// wedges in the bar color at the top and the tray color at the bottom.
class FrameCornersPainter extends CustomPainter {
  const FrameCornersPainter({this.top, this.bottom});

  final Color? top;
  final Color? bottom;

  static const radius = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final corners = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      Path()..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      ),
    );
    void half(Color? color, Rect clip) {
      if (color == null || color.a == 0) return;
      canvas
        ..save()
        ..clipRect(clip)
        ..drawPath(corners, Paint()..color = color)
        ..restore();
    }

    final mid = size.height / 2;
    half(top, Rect.fromLTWH(0, 0, size.width, mid));
    half(bottom, Rect.fromLTWH(0, mid, size.width, size.height - mid));
  }

  @override
  bool shouldRepaint(FrameCornersPainter old) =>
      old.top != top || old.bottom != bottom;
}
