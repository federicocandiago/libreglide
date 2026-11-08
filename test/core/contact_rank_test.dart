import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/contact.dart';

Contact c(String name, {bool starred = false}) =>
    Contact(id: name.hashCode, lookupKey: name, name: name, starred: starred);

void main() {
  // As the system returns them: alphabetical.
  final results = [
    c('Alessia Maria'),
    c('Anna Marchi'),
    c('Carrozzeria Marchioro'),
    c('Marco Rossi'),
    c('Martina Bianchi', starred: true),
  ];

  test('most used first, then favorites, then word starts', () {
    final ranked = rankContacts(results, 'mar', usage: {'Marco Rossi': 2.5});
    expect(ranked.map((x) => x.name).take(2), [
      'Marco Rossi',
      'Martina Bianchi',
    ]);
  });

  test('a word starting with the text beats a match inside a word', () {
    final ranked = rankContacts([
      c('Alessia Amarelli'),
      c('Anna Marchi'),
    ], 'mar');
    expect(ranked.first.name, 'Anna Marchi');
  });

  test('otherwise favorites first, then the original order', () {
    final ranked = rankContacts(results, 'zzz');
    expect(ranked.map((x) => x.name), [
      'Martina Bianchi',
      'Alessia Maria',
      'Anna Marchi',
      'Carrozzeria Marchioro',
      'Marco Rossi',
    ]);
  });
}
