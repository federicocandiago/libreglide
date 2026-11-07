import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/time_context.dart';
import 'package:libreglide/core/wallpaper_moment.dart';
import 'package:libreglide/core/weather.dart';

void main() {
  test('holidays take precedence over everything', () {
    final m = momentFor(
      DateTime(2026, 12, 25, 20),
      travelling: true,
      audio: 'headphones',
    );
    expect(m.id, 'holiday:christmas');
    expect(m.query, 'christmas lights');
  });

  test('Easter and Easter Monday computed', () {
    expect(momentFor(DateTime(2026, 4, 5, 10)).id, 'holiday:easter');
    expect(momentFor(DateTime(2026, 4, 6, 10)).id, 'holiday:easter');
    expect(momentFor(DateTime(2026, 4, 7, 10)).kind, MomentKind.daily);
  });

  test('travelling: city if known, otherwise generic', () {
    final now = DateTime(2026, 11, 5, 10);
    expect(momentFor(now, travelling: true).query, 'travel landscape');
    expect(
      momentFor(now, travelling: true, city: 'Venezia').query,
      'Venezia city',
    );
  });

  test('headphones: music', () {
    final m = momentFor(DateTime(2026, 11, 5, 10), audio: 'bt');
    expect(m.kind, MomentKind.music);
  });

  test('regular day: time slot + season, deterministic', () {
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

  test('photo choice stable within the day, different with shuffle', () {
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

  test('notable weather: after holidays and travel, before music', () {
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
