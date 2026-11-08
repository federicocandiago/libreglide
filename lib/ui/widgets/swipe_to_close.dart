import 'package:flutter/widgets.dart';

import '../gestures.dart';

/// Closes a full-screen page with a vertical swipe in [direction].
///
/// It reads raw pointer events instead of joining the gesture arena, so it
/// never steals drags from the page's list. A swipe counts only if the list
/// ([scroll]) was already at the edge the finger moves away from: swiping
/// down closes only from the top of the list, swiping up only from the
/// bottom (or when the list doesn't scroll).
class SwipeToClose extends StatefulWidget {
  const SwipeToClose({
    super.key,
    required this.direction,
    required this.onClose,
    required this.child,
    this.scroll,
  });

  final SwipeDirection direction;
  final VoidCallback onClose;
  final ScrollController? scroll;
  final Widget child;

  @override
  State<SwipeToClose> createState() => _SwipeToCloseState();
}

class _SwipeToCloseState extends State<SwipeToClose> {
  /// Minimum travel, in logical pixels, and minimum speed (px/ms) for a
  /// fling; a slower swipe needs twice the travel.
  static const _minTravel = 80.0;
  static const _minSpeed = 0.6;

  int? _pointer;
  Offset _start = Offset.zero;
  Duration _startTime = Duration.zero;
  bool _atEdge = false;

  bool _listAtEdge() {
    final c = widget.scroll;
    if (c == null || !c.hasClients) return true;
    final p = c.position;
    return widget.direction == SwipeDirection.down
        ? p.pixels <= p.minScrollExtent + 1
        : p.pixels >= p.maxScrollExtent - 1;
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null) {
      // A second finger: not a swipe.
      _pointer = -1;
      return;
    }
    _pointer = e.pointer;
    _start = e.position;
    _startTime = e.timeStamp;
    _atEdge = _listAtEdge();
  }

  void _up(PointerUpEvent e) {
    final tracked = _pointer == e.pointer;
    if (tracked || _pointer == -1) _pointer = null;
    if (!tracked || !_atEdge) return;
    final d = e.position - _start;
    if (d.dy.abs() < d.dx.abs() * 1.5) return;
    final travel = widget.direction == SwipeDirection.down ? d.dy : -d.dy;
    if (travel < _minTravel) return;
    final ms = (e.timeStamp - _startTime).inMilliseconds.clamp(1, 1 << 30);
    if (travel / ms >= _minSpeed || travel >= _minTravel * 2) {
      widget.onClose();
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (_pointer == e.pointer || _pointer == -1) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}
