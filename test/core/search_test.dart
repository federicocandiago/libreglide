import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/app_entry.dart';
import 'package:libreglide/core/search.dart';

AppEntry app(String pkg, String label) =>
    AppEntry(packageName: pkg, activityName: '.Main', label: label);

void main() {
  final whatsapp = app('com.whatsapp', 'WhatsApp');
  final maps = app('com.google.android.apps.maps', 'Google Maps');
  final gmail = app('com.google.android.gm', 'Gmail');
  final spotify = app('com.spotify.music', 'Spotify');
  final meteo = app('it.meteo', 'Meteo Città');
  final apps = [whatsapp, maps, gmail, spotify, meteo];
  String cat(AppEntry a) => a == spotify ? 'Musica e audio' : 'Altro';

  List<String> labels(List<SearchHit> h) => [for (final x in h) x.app.label];

  test('prima i nomi che iniziano con il testo', () {
    expect(labels(searchApps(apps, 'g')), ['Gmail', 'Google Maps']);
  });

  test('parola interna e iniziali', () {
    expect(matchApp(maps, 'maps'), MatchClass.wordPrefix);
    expect(matchApp(maps, 'gm'), MatchClass.initials);
    expect(labels(searchApps(apps, 'gm')), ['Gmail', 'Google Maps']);
  });

  test('a metà nome e senza accenti', () {
    expect(matchApp(whatsapp, 'app'), MatchClass.substring);
    expect(matchApp(meteo, 'citta'), MatchClass.wordPrefix);
  });

  test('per categoria, solo da 3 lettere', () {
    expect(labels(searchApps(apps, 'musica', categoryLabel: cat)), ['Spotify']);
    expect(matchApp(spotify, 'mu', categoryLabel: 'Musica'), isNull);
  });

  test('a parità di corrispondenza vince il punteggio', () {
    final hits = searchApps(
      apps,
      'g',
      score: {'com.google.android.apps.maps': -1, 'com.google.android.gm': -5},
    );
    expect(labels(hits), ['Google Maps', 'Gmail']);
  });

  test('testo vuoto: nessun risultato', () {
    expect(searchApps(apps, '  '), isEmpty);
  });
}
