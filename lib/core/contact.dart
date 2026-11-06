/// Un contatto per il pannello contatti.
library;

import 'dart:math' as math;
import 'dart:typed_data';

class Contact {
  const Contact({
    required this.id,
    required this.lookupKey,
    required this.name,
    this.number,
    this.photo,
    this.starred = false,
  });

  factory Contact.fromMap(Map<Object?, Object?> m) => Contact(
    id: (m['id'] as num).toInt(),
    lookupKey: m['lookupKey'] as String,
    name: m['name'] as String,
    number: m['number'] as String?,
    photo: m['photo'] is Uint8List ? m['photo'] as Uint8List : null,
    starred: (m['starred'] as bool?) ?? false,
  );

  final int id;
  final String lookupKey;
  final String name;
  final String? number;
  final Uint8List? photo;
  final bool starred;

  /// Iniziali (al massimo due) per l'avatar senza foto.
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => String.fromCharCode(p.runes.first).toUpperCase())
      .join();
}

/// Emivita dell'uso dei contatti.
const Duration contactHalfLife = Duration(days: 30);

/// Peso d'uso di un contatto riportato a [now]: si dimezza ogni 30 giorni.
/// A ogni uso: `w = decayedWeight(w, updated, now) + 1`.
double decayedWeight(double weight, DateTime updated, DateTime now) {
  final age = now.difference(updated);
  if (age <= Duration.zero) return weight;
  return weight *
      math.pow(0.5, age.inMinutes / contactHalfLife.inMinutes).toDouble();
}
