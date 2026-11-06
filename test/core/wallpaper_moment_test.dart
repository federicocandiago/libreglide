import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/time_context.dart';
import 'package:libreglide/core/wallpaper_moment.dart';
import 'package:libreglide/core/weather.dart';

void main() {
  test('le festività hanno la precedenza su tutto', () {
    final m = momentFor(
      DateTime(2026, 12, 25, 20),
      travelling: true,
      audio: 'headphones',
    );
    expect(m.id, 'holiday:christmas');
    expect(m.query, 'christmas lights');
  });

  test('Pasqua e Pasquetta calcolate', () {
    expect(momentFor(DateTime(2026, 4, 5, 10)).id, 'holiday:easter');
    expect(momentFor(DateTime(2026, 4, 6, 10)).id, 'holiday:easter');
    expect(momentFor(DateTime(2026, 4, 7, 10)).kind, MomentKind.daily);
  });

  test('in viaggio: città se nota, altrimenti generico', () {
    final now = DateTime(2026, 11, 5, 10);
    expect(momentFor(now, travelling: true).query, 'travel landscape');
    expect(
      momentFor(now, travelling: true, city: 'Venezia').query,
      'Venezia city',
    );
  });

  test('cuffie: musica', () {
    final m = momentFor(DateTime(2026, 11, 5, 10), audio: 'bt');
    expect(m.kind, MomentKind.music);
  });

  test('giornata normale: fascia oraria + stagione, deterministico', () {
    final a = momentFor(DateTime(2026, 11, 5, 20));
    final b = momentFor(DateTime(2026, 11, 5, 20, 45));
    expect(a.id, 'daily:evening:autumn');
    expect(a.query, 'sunset autumn');
    expect(a.id, b.id);
    expect(
      momentFor(DateTime(2026, 7, 10, 6, 30), slot: Slot.wakeUp).query,
      'sunrise summer',
    );
  });

  test('scelta della foto stabile nel giorno, diversa con shuffle', () {
    final day = DateTime(2026, 11, 5);
    final i1 = pickIndex('sunset autumn', day, 10);
    final i2 = pickIndex('sunset autumn', day, 10);
    expect(i1, i2);
    expect(i1, inInclusiveRange(0, 9));
    final shuffled = {
      for (var s = 0; s < 10; s++)
        pickIndex('sunset autumn', day, 10, shuffle: s),
    };
    expect(shuffled.length, greaterThan(1));
    expect(pickIndex('x', day, 0), 0);
  });

  test('meteo notevole: dopo festività e viaggio, prima della musica', () {
    final now = DateTime(2026, 11, 5, 10);
    expect(
      momentFor(now, weather: WeatherKind.rain, audio: 'bt').id,
      'weather:rain',
    );
    expect(momentFor(now, weather: WeatherKind.snow).query, 'snowy street');
    expect(momentFor(now, weather: WeatherKind.clear).kind, MomentKind.daily);
    expect(
      momentFor(now, weather: WeatherKind.storm, travelling: true).kind,
      MomentKind.travel,
    );
    expect(
      momentFor(DateTime(2026, 12, 25), weather: WeatherKind.snow).kind,
      MomentKind.holiday,
    );
  });
}
