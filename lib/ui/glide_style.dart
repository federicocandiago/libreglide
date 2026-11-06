/// Linguaggio visivo di libreGLIDE: l'impostazione di Glide (barre e card
/// piatte, maiuscoletto spaziato, caratteri sottili, colore per Space) con
/// piccoli tocchi Material You (accento dinamico, grigi tinti, colori degli
/// Space armonizzati con la palette, angoli 12 dp).
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/space.dart';
import '../core/time_context.dart';

/// Linguaggio comune (v0.4): impostazione Glide, forme e toni di Android 17.
///
/// - card senza bordo, separate dal tono della pagina;
/// - angoli: 24 card, 28 fogli e dialoghi, 16 elementi interni, pillola per
///   campi di ricerca e pulsanti;
/// - spazi: 10 tra le card e dai bordi, 16 dentro le card.
const double cardRadius = 24;

/// Raggio degli elementi dentro le card (riquadri, scelte, icone quadrate).
const double innerRadius = 16;

/// Raggio di fogli dal basso e dialoghi.
const double sheetRadius = 28;

/// Spazio interno orizzontale delle card.
const double cardPadding = 16;

/// Spazio tra le card e dai bordi.
const double cardGap = 10;

/// Altezza della barra delle schede.
const double tabBarHeight = 56;

/// Fattore massimo per il testo delle etichette delle icone, come nel
/// Pixel Launcher: con caratteri di sistema grandi le etichette restano
/// leggibili senza troncarsi del tutto.
const double maxLabelScale = 1.15;

/// Vetro smerigliato attivo per le pagine sotto questo widget: fondi e card
/// diventano semitrasparenti sopra lo sfondo sfocato.
class Glass extends InheritedWidget {
  const Glass({super.key, required this.level, required super.child});

  /// 0 = spento, 1 = sfocatura attiva, 2 = sfocatura non disponibile
  /// (risparmio energetico): fondi quasi pieni, per restare leggibili.
  final int level;

  @override
  bool updateShouldNotify(Glass old) => old.level != level;
}

class GlideColors {
  const GlideColors._(this.scheme, this._glass);

  factory GlideColors.of(BuildContext context) => GlideColors._(
    Theme.of(context).colorScheme,
    context.dependOnInheritedWidgetOfExactType<Glass>()?.level ?? 0,
  );

  final ColorScheme scheme;
  final int _glass;

  bool get _dark => scheme.brightness == Brightness.dark;

  /// Fondo delle pagine (il grigio chiaro di Glide, tinto dalla palette).
  Color get page {
    final base = _dark ? scheme.surface : scheme.surfaceContainerHigh;
    return switch (_glass) {
      1 => base.withValues(alpha: _dark ? 0.45 : 0.5),
      2 => base.withValues(alpha: 0.9),
      _ => base,
    };
  }

  /// Card e barre (il "bianco" di Glide, appena tinto: le icone con il
  /// fondo bianco restano riconoscibili anche nel tema chiaro).
  Color get card => glassCard(scheme, _glass);

  /// Colore delle card per un livello di vetro (0 = pieno).
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

  /// Elementi in rilievo dentro le card o sopra la pagina (campi di ricerca,
  /// scelte non selezionate).
  Color get raised =>
      _dark ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh;

  /// Linee sottili tra le righe di una card (le card non hanno bordo).
  Color get hairline =>
      scheme.outlineVariant.withValues(alpha: _dark ? 0.35 : 0.6);

  /// Testo secondario e maiuscoletti.
  Color get muted => scheme.onSurfaceVariant;

  /// Accento: lettere A-Z, indicatore, banner.
  Color get accent => scheme.primary;

  /// Cassetto degli Space: quasi nero, leggermente tinto.
  Color get drawer => Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.06),
    const Color(0xFF101010),
  );

  /// Colore di uno Space, armonizzato con la palette corrente.
  Color space(Slot slot) => spaceBaseColor(slot).harmonizeWith(scheme.primary);

  /// Colore di uno Space (di contesto o dell'ora), armonizzato.
  Color spaceKind(SpaceKind k) => switch (k) {
    SpaceKind.home => const Color(0xFFF28C38),
    SpaceKind.work => const Color(0xFF3B7DD8),
    SpaceKind.moving => const Color(0xFF43A047),
    SpaceKind.listening => const Color(0xFFE0533D),
    SpaceKind.travel => const Color(0xFF26A69A),
    _ => spaceBaseColor(k.slot!),
  }.harmonizeWith(scheme.primary);
}

/// Colori di base degli Space (ognuno ha il suo, come in Glide).
Color spaceBaseColor(Slot slot) => switch (slot) {
  Slot.wakeUp => const Color(0xFFF5A623),
  Slot.morning => const Color(0xFFF2C12E),
  Slot.lunch => const Color(0xFFF26B3A),
  Slot.afternoon => const Color(0xFF3BAF6A),
  Slot.evening => const Color(0xFF6A5ACD),
  Slot.night => const Color(0xFF2F4F9F),
};

/// Maiuscoletto spaziato delle intestazioni ("SOCIAL", "A-Z APP").
TextStyle capsStyle(BuildContext context, {Color? color, double size = 12.5}) =>
    TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: color ?? GlideColors.of(context).muted,
    );

/// Titolo sottile maiuscolo (nome dello Space nella striscia colorata).
TextStyle thinTitleStyle({required Color color, double size = 24}) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w300,
  letterSpacing: 1.2,
  color: color,
);

/// Card piatta di Glide: fondo bianco, bordo sottile, nessuna ombra.
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

/// Intestazione di una card: piccola icona grigia, maiuscoletto, freccia.
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

/// Freccia sottile ∨ che ruota quando la card è aperta.
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

/// Barra di ricerca a pillola (stile Android 17), per ricerca e contatti.
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

  /// Toccata la X con il campo vuoto (di solito chiude la pagina).
  final VoidCallback? onClose;

  @override
  State<PillSearchField> createState() => _PillSearchFieldState();
}

class _PillSearchFieldState extends State<PillSearchField> {
  final _focus = FocusNode();
  Animation<double>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autofocus || _route != null) return;
    // L'autofocus da solo a volte non apre la tastiera (la finestra non ha
    // ancora il focus mentre la pagina entra): a transizione finita si
    // richiede il focus e si mostra la tastiera esplicitamente.
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

  void _showKeyboard() {
    if (!mounted) return;
    if (!_focus.hasFocus) _focus.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRoute);
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

/// Colore pieno della barra delle schede e del vassoio del dock (anche con
/// il vetro attivo: sulla Home restano pieni).
Color solidBarColor(BuildContext context) =>
    GlideColors.glassCard(Theme.of(context).colorScheme, 0);

/// Angoli appena arrotondati della "finestra" sullo sfondo della Home:
/// spicchi del colore della barra in alto e del vassoio in basso.
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
