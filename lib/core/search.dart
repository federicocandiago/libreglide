/// Ricerca delle app per la ricerca globale.
///
/// Ordine dei risultati, per classe di corrispondenza:
/// 1. il nome inizia con il testo ("whats" → WhatsApp)
/// 2. una parola del nome inizia con il testo ("maps" → Google Maps)
/// 3. le iniziali delle parole iniziano con il testo ("gm" → Google Maps)
/// 4. il testo compare dentro il nome ("app" → WhatsApp)
/// 5. il nome della categoria corrisponde ("musica" → Spotify)
///
/// A parità di classe vince il punteggio del predittore (frequenza,
/// recentezza e contesto), poi l'ordine alfabetico.
library;

import 'app_entry.dart';

enum MatchClass { prefix, wordPrefix, initials, substring, category }

class SearchHit {
  const SearchHit(this.app, this.match);
  final AppEntry app;
  final MatchClass match;
}

/// Le parole di un nome normalizzato (spazi, trattini, punti).
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

/// Cerca [query] tra [apps]. [score] è il punteggio del predittore per
/// pacchetto (più alto = più probabile); le app senza punteggio vengono dopo.
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
