import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/settings.dart';
import 'contacts_page.dart';
import 'search_page.dart';

/// Direction of a vertical swipe (the way the finger moves).
enum SwipeDirection {
  up,
  down;

  SwipeDirection get opposite => this == up ? down : up;
}

/// Runs the action bound to a swipe (Settings → Search and gestures). The
/// page opens following the finger and closes with the opposite swipe.
void runGesture(
  BuildContext context,
  GestureAction action,
  SwipeDirection swipe,
) {
  switch (action) {
    case GestureAction.search:
      showGlobalSearch(context, openedBy: swipe);
    case GestureAction.contacts:
      showContactsPanel(context, openedBy: swipe);
    case GestureAction.none:
      break;
  }
}

/// How much more finger movement a horizontal swipe between tabs needs to
/// start than a vertical one (scrolling, swipe to search or contacts). With
/// the same threshold a thumb swipe, which starts slightly sideways, was
/// often taken as a page change; with twice the threshold a swipe counts as
/// vertical up to about 27° from horizontal instead of 45°.
const double tabSwipeSlopFactor = 2;

/// Sets the touch slop (pixels a finger moves before a drag starts) for
/// [child]; null restores the device default.
class TouchSlop extends StatelessWidget {
  const TouchSlop({super.key, required this.slop, required this.child});

  final double? slop;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(gestureSettings: DeviceGestureSettings(touchSlop: slop)),
    child: child,
  );
}

/// Whether a vertical drag that ended with [velocity] after moving [dy]
/// pixels is a swipe in [direction]: fast enough, or long enough without
/// being thrown back the other way.
bool isVerticalSwipe(double velocity, double dy, SwipeDirection direction) {
  const minVelocity = 300.0;
  const minDistance = 72.0;
  final sign = direction == SwipeDirection.down ? 1 : -1;
  return velocity * sign > minVelocity ||
      (dy * sign > minDistance && velocity * sign > -50);
}
