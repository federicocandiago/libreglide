/// Carattere di sistema dei Pixel (Google Sans), caricato dal telefono.
///
/// libreGLIDE non include file di caratteri: se il telefono ha Google Sans
/// (i Pixel con Android 12+ lo usano per l'interfaccia di sistema), lo
/// carica dai file di sistema così il testo appare come quello di Android 17.
/// Altrimenti resta il carattere predefinito (Roboto).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String systemFontFamily = 'LGSans';

/// Carica il carattere e restituisce il nome della famiglia, o null.
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
    // Preferenza: Google Sans Flex (il carattere di Android 16/17, variabile),
    // poi Google Sans Text e Google Sans (statici o variabili).
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
        'libreglide: carattere di sistema ${set.map(name).join(', ')}',
      );
      return systemFontFamily;
    }
  } catch (e) {
    debugPrint('libreglide: carattere di sistema non disponibile: $e');
  }
  return null;
}
