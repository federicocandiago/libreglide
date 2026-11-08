/// Screen orientation of the launcher.
library;

import 'package:flutter/services.dart';

/// Portrait only, or follow the phone's rotation (an empty list lets the
/// system decide, honoring the auto-rotate setting).
Future<void> applyOrientation({required bool lockPortrait}) =>
    SystemChrome.setPreferredOrientations(
      lockPortrait ? const [DeviceOrientation.portraitUp] : const [],
    );
