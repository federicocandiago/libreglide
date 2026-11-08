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
