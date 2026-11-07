// Generates docs/PRIVACY.md from the text shown in the app.
// Usage: dart run tool/privacy_md.dart
import 'dart:io';

import 'package:libreglide/legal/privacy_policy.dart';

void main() {
  final out = StringBuffer();
  for (final (lang, title, note) in [
    ('it', 'Informativa sulla privacy', 'Stesso testo mostrato nell\'app'),
    ('en', 'Privacy policy', 'Same text shown in the app'),
  ]) {
    out
      ..writeln('# libreGLIDE — $title')
      ..writeln()
      ..writeln(
        '> $note (`lib/legal/privacy_policy.dart`). '
        'v$policyVersion, ${policyDate(lang)}.',
      )
      ..writeln();
    for (final s in privacyPolicy(lang)) {
      out
        ..writeln('## ${s.title}')
        ..writeln();
      for (final p in s.paragraphs) {
        out
          ..writeln(p)
          ..writeln();
      }
    }
  }
  File('docs/PRIVACY.md').writeAsStringSync('${out.toString().trimRight()}\n');
}
