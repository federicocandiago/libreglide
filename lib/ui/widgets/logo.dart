import 'package:flutter/material.dart';

/// Logo di libreGLIDE: un aliante che plana davanti al sole (stesso disegno
/// di docs/icon/libreglide-icon.svg, nelle coordinate 108×108 dell'icona).
class LibreGlideLogo extends StatelessWidget {
  const LibreGlideLogo({
    super.key,
    this.size = 72,
    this.monochrome = false,
    this.withBackground = false,
    this.background,
  });

  final double size;

  /// Bianco e nero: sole pieno nel colore del testo, aliante staccato da un
  /// bordo del colore dello sfondo.
  final bool monochrome;

  /// Con il fondo arrotondato dell'icona.
  final bool withBackground;

  /// Colore su cui sta il logo (per il bordo del bianco e nero).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        monochrome: monochrome,
        withBackground: withBackground,
        ink: scheme.onSurface,
        paper: withBackground
            ? const Color(0xFFFFFCF6)
            : background != null
            ? background!
            : Theme.of(context).scaffoldBackgroundColor == Colors.transparent
            ? scheme.surface
            : Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

/// Percorsi dell'aliante (ala, timone, deriva, fusoliera) e del tettuccio.
const _glider = [
  'M3,69 C30,62 62,53.2 104.5,38.6 C105,39.3 104.4,40 103.4,40.4 C72,52.6 44,60.2 3.6,70.4 C2.7,70.5 2.5,69.3 3,69 Z',
  'M31.5,54 C38,52.4 45,50.8 50.2,49.6 C50.5,50.2 50.1,50.6 49.4,50.7 C44,51.9 38,53.3 31.8,54.9 C31.2,55 31.1,54.2 31.5,54 Z',
  'M40.6,58.6 L43.4,58 L41.2,52.4 L38.9,52.7 Z',
  'M40.6,59.4 C52,57.8 62,56.8 70,56 C75,55.5 79.8,55.7 80,54.6 C80.2,53 76,51.4 70,51.5 C64,51.6 58,53.4 52,55.3 C47,56.8 43.4,57.6 40.4,58 C39.6,58.2 39.8,59.5 40.6,59.4 Z',
];
const _canopy =
    'M63.2,53.7 C64.8,52.4 69,51.9 71.8,52.3 C70.2,53.2 66,53.9 63.2,53.7 Z';

/// Interpreta i percorsi SVG usati qui (solo M, L, C, Z assoluti).
Path _parse(String d) {
  final path = Path();
  final tokens = [
    for (final m in RegExp(r'[MLCZ]|-?\d*\.?\d+').allMatches(d)) m[0]!,
  ];
  var i = 0;
  String? cmd;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if ('MLCZ'.contains(tokens[i])) {
      cmd = tokens[i++];
      if (cmd == 'Z') {
        path.close();
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        path.moveTo(n(), n());
      case 'L':
        path.lineTo(n(), n());
      case 'C':
        path.cubicTo(n(), n(), n(), n(), n(), n());
      default:
        i++;
    }
  }
  return path;
}

final _gliderPaths = [for (final d in _glider) _parse(d)];
final _canopyPath = _parse(_canopy);

class _LogoPainter extends CustomPainter {
  const _LogoPainter({
    required this.monochrome,
    required this.withBackground,
    required this.ink,
    required this.paper,
  });

  final bool monochrome;
  final bool withBackground;
  final Color ink;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.3),
        ),
        Paint()..color = paper,
      );
      // L'icona occupa la zona sicura (72 su 108).
      canvas.scale(size.width / 72);
      canvas.translate(-18, -18);
    } else {
      // Senza fondo si mostra tutto l'aliante, ali comprese.
      canvas.scale(size.width / 104);
      canvas.translate(-2, -2);
    }

    const sun = Rect.fromLTWH(28, 28, 52, 52);
    canvas.drawOval(
      sun,
      Paint()
        ..color = ink
        ..shader = monochrome
            ? null
            : const LinearGradient(
                begin: Alignment(0.5, -0.9),
                end: Alignment(-0.4, 1),
                colors: [Color(0xFFFFC81E), Color(0xFFFF7420)],
              ).createShader(sun),
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeJoin = StrokeJoin.round
      ..color = monochrome ? paper : Colors.white;
    final fill = Paint()..color = monochrome ? ink : const Color(0xFF14235A);
    final fillStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeJoin = StrokeJoin.round
      ..color = fill.color;
    for (final p in _gliderPaths) {
      canvas
        ..drawPath(p, outline)
        ..drawPath(p, Paint()..color = outline.color);
    }
    for (final p in _gliderPaths) {
      canvas
        ..drawPath(p, fill)
        ..drawPath(p, fillStroke);
    }
    canvas.drawPath(
      _canopyPath,
      Paint()..color = monochrome ? paper : Colors.white,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.monochrome != monochrome ||
      old.withBackground != withBackground ||
      old.ink != ink ||
      old.paper != paper;
}
