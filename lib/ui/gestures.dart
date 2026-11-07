import 'package:flutter/material.dart';

import '../data/settings.dart';
import 'contacts_page.dart';
import 'search_page.dart';

/// Runs the action bound to a swipe (Settings → Search and gestures).
void runGesture(BuildContext context, GestureAction action) {
  switch (action) {
    case GestureAction.search:
      showGlobalSearch(context);
    case GestureAction.contacts:
      showContactsPanel(context);
    case GestureAction.none:
      break;
  }
}
