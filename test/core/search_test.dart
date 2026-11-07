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

  test('names starting with the query come first', () {
    expect(labels(searchApps(apps, 'g')), ['Gmail', 'Google Maps']);
  });

  test('inner word and initials', () {
    expect(matchApp(maps, 'maps'), MatchClass.wordPrefix);
    expect(matchApp(maps, 'gm'), MatchClass.initials);
    expect(labels(searchApps(apps, 'gm')), ['Gmail', 'Google Maps']);
  });

  test('mid-name and accent-insensitive', () {
    expect(matchApp(whatsapp, 'app'), MatchClass.substring);
    expect(matchApp(meteo, 'citta'), MatchClass.wordPrefix);
  });

  test('by category, only from 3 letters on', () {
    expect(labels(searchApps(apps, 'musica', categoryLabel: cat)), ['Spotify']);
    expect(matchApp(spotify, 'mu', categoryLabel: 'Musica'), isNull);
  });

  test('on an equal match, the score wins', () {
    final hits = searchApps(
      apps,
      'g',
      score: {'com.google.android.apps.maps': -1, 'com.google.android.gm': -5},
    );
    expect(labels(hits), ['Google Maps', 'Gmail']);
  });

  test('empty query: no results', () {
    expect(searchApps(apps, '  '), isEmpty);
  });
}
