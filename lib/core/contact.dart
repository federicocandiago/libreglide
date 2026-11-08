/// A contact for the contacts panel.
library;

import 'dart:math' as math;

class Contact {
  const Contact({
    required this.id,
    required this.lookupKey,
    required this.name,
    this.number,
    this.hasPhoto = false,
    this.starred = false,
  });

  factory Contact.fromMap(Map<Object?, Object?> m) => Contact(
    id: (m['id'] as num).toInt(),
    lookupKey: m['lookupKey'] as String,
    name: m['name'] as String,
    number: m['number'] as String?,
    hasPhoto: (m['hasPhoto'] as bool?) ?? false,
    starred: (m['starred'] as bool?) ?? false,
  );

  final int id;
  final String lookupKey;
  final String name;
  final String? number;

  /// Whether the contact has a photo; the image itself is loaded on demand
  /// (see `ContactsController.photo`).
  final bool hasPhoto;
  final bool starred;

  /// Initials (at most two) for the avatar without a photo.
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => String.fromCharCode(p.runes.first).toUpperCase())
      .join();
}

/// Half-life of contact usage.
const Duration contactHalfLife = Duration(days: 30);

/// Usage weight of a contact decayed to [now]: it halves every 30 days.
/// On each use: `w = decayedWeight(w, updated, now) + 1`.
double decayedWeight(double weight, DateTime updated, DateTime now) {
  final age = now.difference(updated);
  if (age <= Duration.zero) return weight;
  return weight *
      math.pow(0.5, age.inMinutes / contactHalfLife.inMinutes).toDouble();
}

/// Orders search results so that the best match comes first: the contacts
/// used most from the panel ([usage], decayed weights by lookup key), then
/// favorites, then names with a word starting with [query], then
/// alphabetical (the order they came in).
List<Contact> rankContacts(
  List<Contact> results,
  String query, {
  Map<String, double> usage = const {},
}) {
  final q = query.trim().toLowerCase();
  bool wordStart(Contact c) =>
      c.name.toLowerCase().split(RegExp(r'\s+')).any((w) => w.startsWith(q));
  final indexed = results.indexed.toList();
  indexed.sort((a, b) {
    final (ia, ca) = a;
    final (ib, cb) = b;
    final ua = usage[ca.lookupKey] ?? 0, ub = usage[cb.lookupKey] ?? 0;
    if (ua != ub) return ub.compareTo(ua);
    if (ca.starred != cb.starred) return ca.starred ? -1 : 1;
    final pa = wordStart(ca), pb = wordStart(cb);
    if (pa != pb) return pa ? -1 : 1;
    return ia.compareTo(ib);
  });
  return [for (final (_, c) in indexed) c];
}
