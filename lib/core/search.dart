/// App matching for the global search.
///
/// Result order, by match class:
/// 1. the name starts with the query ("whats" → WhatsApp)
/// 2. a word of the name starts with the query ("maps" → Google Maps)
/// 3. the word initials start with the query ("gm" → Google Maps)
/// 4. the query appears inside the name ("app" → WhatsApp)
/// 5. the category name matches ("music" → Spotify)
///
/// Within the same class the predictor score wins (frequency, recency and
/// context), then alphabetical order.
library;

import 'app_entry.dart';

enum MatchClass { prefix, wordPrefix, initials, substring, category }

class SearchHit {
  const SearchHit(this.app, this.match);
  final AppEntry app;
  final MatchClass match;
}

/// The words of a normalized name (split on spaces, dashes, dots).
List<String> _words(String normalized) => normalized
    .split(RegExp(r'[\s\-_.:/]+'))
    .where((w) => w.isNotEmpty)
    .toList();

MatchClass? matchApp(AppEntry app, String query, {String? categoryLabel}) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return null;
  final name = app.sortKey;
  if (name.startsWith(q)) return MatchClass.prefix;
  final words = _words(name);
  if (words.skip(1).any((w) => w.startsWith(q))) return MatchClass.wordPrefix;
  if (q.length >= 2 && words.length >= 2) {
    final initials = words.map((w) => w[0]).join();
    if (initials.startsWith(q)) return MatchClass.initials;
  }
  if (name.contains(q)) return MatchClass.substring;
  if (categoryLabel != null && q.length >= 3) {
    final cat = normalizeForSearch(categoryLabel);
    if (cat.startsWith(q) || _words(cat).any((w) => w.startsWith(q))) {
      return MatchClass.category;
    }
  }
  return null;
}

/// Searches [query] among [apps]. [score] is the predictor score per package
/// (higher = more likely); apps without a score come after.
List<SearchHit> searchApps(
  List<AppEntry> apps,
  String query, {
  Map<String, double> score = const {},
  String Function(AppEntry)? categoryLabel,
}) {
  final hits = <SearchHit>[];
  for (final a in apps) {
    final m = matchApp(a, query, categoryLabel: categoryLabel?.call(a));
    if (m != null) hits.add(SearchHit(a, m));
  }
  hits.sort((x, y) {
    final c = x.match.index.compareTo(y.match.index);
    if (c != 0) return c;
    final sx = score[x.app.packageName] ?? double.negativeInfinity;
    final sy = score[y.app.packageName] ?? double.negativeInfinity;
    final s = sy.compareTo(sx);
    if (s != 0) return s;
    return x.app.sortKey.compareTo(y.app.sortKey);
  });
  return hits;
}
