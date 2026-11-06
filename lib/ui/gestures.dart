import 'package:flutter/material.dart';

import '../data/settings.dart';
import 'contacts_page.dart';
import 'search_page.dart';

/// Esegue l'azione associata a uno swipe (Impostazioni → Ricerca e gesti).
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
