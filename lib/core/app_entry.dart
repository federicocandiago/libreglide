/// A launchable app (an activity with the LAUNCHER category).
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

  /// Unique identifier: a package can have several launchable activities.
  String get id => '$packageName/$activityName';

  /// Key for alphabetical sorting: lowercase and without accents.
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

/// Lowercases and strips accents, for search and sorting.
String normalizeForSearch(String s) {
  final lower = s.toLowerCase().trim();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_accents[ch] ?? ch);
  }
  return b.toString();
}

/// Section letter for the A-Z view: A–Z, or `#`.
String sectionLetter(String label) {
  final n = normalizeForSearch(label);
  if (n.isEmpty) return '#';
  final c = n.codeUnitAt(0);
  if (c >= 0x61 && c <= 0x7a) return String.fromCharCode(c - 32);
  return '#';
}
