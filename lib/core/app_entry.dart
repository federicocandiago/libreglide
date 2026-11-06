/// Un'app avviabile (un'activity con categoria LAUNCHER).
library;

class AppEntry {
  const AppEntry({
    required this.packageName,
    required this.activityName,
    required this.label,
    this.isSystem = false,
    this.manifestCategory,
  });

  factory AppEntry.fromMap(Map<Object?, Object?> m) => AppEntry(
    packageName: m['package'] as String,
    activityName: m['activity'] as String,
    label: (m['label'] as String?) ?? (m['package'] as String),
    isSystem: (m['system'] as bool?) ?? false,
    manifestCategory: m['category'] as int?,
  );

  final String packageName;
  final String activityName;
  final String label;
  final bool isSystem;
  final int? manifestCategory;

  /// Identificatore univoco: un pacchetto può avere più activity avviabili.
  String get id => '$packageName/$activityName';

  /// Chiave per l'ordinamento alfabetico: minuscole e senza accenti.
  String get sortKey => normalizeForSearch(label);

  @override
  bool operator ==(Object other) => other is AppEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppEntry($label, $id)';
}

const _accents = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ß': 'ss',
};

/// Minuscole e senza accenti, per ricerca e ordinamento.
String normalizeForSearch(String s) {
  final lower = s.toLowerCase().trim();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_accents[ch] ?? ch);
  }
  return b.toString();
}

/// Lettera di sezione per la vista A-Z: A–Z, oppure `#`.
String sectionLetter(String label) {
  final n = normalizeForSearch(label);
  if (n.isEmpty) return '#';
  final c = n.codeUnitAt(0);
  if (c >= 0x61 && c <= 0x7a) return String.fromCharCode(c - 32);
  return '#';
}
