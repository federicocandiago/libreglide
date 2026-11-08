import 'package:flutter/material.dart';

/// Collections icon: three equal, thin rows with rounded ends, the same
/// weight as the lines of the Spaces drawer icon and of "A-Z" (the Material
/// rows icons are much heavier).
class RowsIcon extends StatelessWidget {
  const RowsIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _RowsPainter(color),
  );
}

class _RowsPainter extends CustomPainter {
  const _RowsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;
    // Three rows 5 units apart, centered; 3..21 wide like the Material grid.
    for (final y in [7.0, 12.0, 17.0]) {
      canvas.drawLine(Offset(3.5 * s, y * s), Offset(20.5 * s, y * s), paint);
    }
  }

  @override
  bool shouldRepaint(_RowsPainter old) => old.color != color;
}
