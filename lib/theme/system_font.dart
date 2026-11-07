/// Pixel system font (Google Sans), loaded from the phone.
///
/// libreGLIDE bundles no font files: if the phone has Google Sans (Pixels on
/// Android 12+ use it for the system UI), it is loaded from the system files
/// so text looks like Android 17's. Otherwise the default font (Roboto) is
/// kept.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String systemFontFamily = 'LGSans';

/// Loads the font and returns the family name, or null.
Future<String?> loadSystemFont() async {
  if (!Platform.isAndroid) return null;
  try {
    final files = <File>[];
    for (final dir in ['/product/fonts', '/system/fonts']) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      files.addAll(d.listSync().whereType<File>());
    }
    String name(File f) => f.uri.pathSegments.last;
    bool upright(File f) =>
        name(f).toLowerCase().endsWith('.ttf') &&
        !name(f).toLowerCase().contains('italic') &&
        !name(f).toLowerCase().contains('clock');
    // Preference: Google Sans Flex (Android 16/17's variable font), then
    // Google Sans Text and Google Sans (static or variable).
    for (final prefix in [
      'GoogleSansFlex-',
      'GoogleSansText-',
      'GoogleSans-',
    ]) {
      final set = files
          .where((f) => name(f).startsWith(prefix) && upright(f))
          .toList();
      if (set.isEmpty) continue;
      final loader = FontLoader(systemFontFamily);
      for (final f in set) {
        loader.addFont(f.readAsBytes().then(ByteData.sublistView));
      }
      await loader.load();
      debugPrint(
        'libreglide: system font ${set.map(name).join(', ')}',
      );
      return systemFontFamily;
    }
  } catch (e) {
    debugPrint('libreglide: system font unavailable: $e');
  }
  return null;
}
