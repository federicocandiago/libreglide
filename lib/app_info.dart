/// Facts about the installed app, read once at startup.
library;

import 'package:package_info_plus/package_info_plus.dart';

/// Version name of the installed APK (from pubspec.yaml `version:`), so it
/// never has to be updated by hand.
String appVersion = '';

/// Reads [appVersion] from the package; call before `runApp`.
Future<void> loadAppInfo() async {
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    appVersion = '';
  }
}
