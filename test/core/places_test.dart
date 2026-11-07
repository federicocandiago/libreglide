import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/places.dart';

/// Places used in the simulation.
typedef Spot = (double, double, String?);
const Spot home = (45.4371, 12.3326, 'wifi-home');
const Spot work = (45.4900, 12.2400, 'wifi-work');
const Spot gym = (45.4600, 12.3000, null);
const Spot hotel = (46.9000, 11.4000, 'wifi-hotel');

/// A sample at [spot] at [h]:[m] on day [day].
LocationSample at(
  DateTime day,
  int h,
  Spot spot, {
  int m = 0,
  bool charging = false,
  String? wifiOverride,
}) => LocationSample(
  ts: DateTime(day.year, day.month, day.day, h, m),
  lat: spot.$1,
  lon: spot.$2,
  accuracy: 20,
  wifi: wifiOverride ?? spot.$3,
  charging: charging,
);

/// Typical day of a 9–18 office worker (weekends at home and at the gym).
List<LocationSample> officeDay(DateTime d) {
  final weekend = d.weekday >= DateTime.saturday;
  return [
    at(d, 7, home, charging: true),
    at(d, 7, home, m: 40),
    if (!weekend) ...[
      for (var h = 9; h <= 17; h++) at(d, h, work),
      at(d, 18, home, m: 40),
    ] else ...[
      at(d, 10, home),
      at(d, 13, home),
      at(d, 17, gym),
      at(d, 18, gym),
    ],
    at(d, 20, home),
    at(d, 22, home),
    at(d, 23, home, charging: true),
  ];
}

/// Day of someone who works from home.
List<LocationSample> remoteDay(DateTime d) => [
  at(d, 7, home, charging: true),
  for (var h = 9; h <= 18; h++) at(d, h, home),
  at(d, 23, home, charging: true),
];

/// Night shift 22–6 on weekdays, sleeping 8–15 at home.
List<LocationSample> nightShiftDay(DateTime d) {
  final weekend = d.weekday >= DateTime.saturday;
  return [
    if (!weekend) ...[
      for (var h = 0; h <= 5; h++) at(d, h, work),
      at(d, 7, home, charging: true),
      at(d, 15, home, m: 30),
      at(d, 17, home),
      at(d, 19, home),
      at(d, 21, home),
      at(d, 22, work),
      at(d, 23, work),
    ] else ...[
      at(d, 9, home),
      at(d, 13, home),
      at(d, 20, home),
      at(d, 23, home, charging: true),
    ],
  ];
}

/// Runs the engine as on the phone: samples fed in one at a time, roles
/// recomputed at the end of each day.
PlaceEngine simulate(
  DateTime start,
  int days,
  List<LocationSample> Function(DateTime) dayFn, {
  PlaceEngine? engine,
  List<LocationSample>? samples,
  List<int?>? placeOf,
}) {
  final e = engine ?? PlaceEngine();
  final s = samples ?? <LocationSample>[];
  final p = placeOf ?? <int?>[];
  for (var i = 0; i < days; i++) {
    final d = start.add(Duration(days: i));
    for (final sample in dayFn(d)) {
      s.add(sample);
      p.add(e.addSample(sample));
    }
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59);
    e
      ..maintain(endOfDay)
      ..inferRoles(s, p, endOfDay);
  }
  return e;
}

bool near(Place? p, Spot s) =>
    p != null && distanceMeters(p.lat, p.lon, s.$1, s.$2) < 150;

void main() {
  final monday = DateTime(2026, 10, 5);

  test('office worker: home and work detected, gym frequent', () {
    final e = simulate(monday, 14, officeDay);
    final h = e.withRole(PlaceRole.home);
    final w = e.withRole(PlaceRole.work);
    expect(near(h, home), isTrue);
    expect(near(w, work), isTrue);
    expect(h!.roleConfidence, greaterThanOrEqualTo(roleThreshold));
    expect(w!.roleConfidence, greaterThanOrEqualTo(roleThreshold));
    final g = e.places.where((p) => near(p, gym)).single;
    expect(g.effectiveRole, PlaceRole.frequent);
  });

  test('office worker: no commitment after only a few days', () {
    final e = simulate(monday, 2, officeDay);
    expect(e.withRole(PlaceRole.home), isNull);
    expect(e.withRole(PlaceRole.work), isNull);
  });

  test('remote worker: home yes, work no', () {
    final e = simulate(monday, 14, remoteDay);
    expect(near(e.withRole(PlaceRole.home), home), isTrue);
    expect(e.withRole(PlaceRole.work), isNull);
  });

  test('night shift: home is where you sleep, even by day', () {
    final e = simulate(monday, 14, nightShiftDay);
    expect(near(e.withRole(PlaceRole.home), home), isTrue);
  });

  test('far-away holiday: the hotel does not become home', () {
    final samples = <LocationSample>[];
    final placeOf = <int?>[];
    final e = simulate(
      monday,
      14,
      officeDay,
      samples: samples,
      placeOf: placeOf,
    );
    simulate(
      monday.add(const Duration(days: 14)),
      7,
      (d) => [
        at(d, 8, hotel, charging: true),
        at(d, 12, hotel),
        at(d, 18, hotel),
        at(d, 23, hotel, charging: true),
      ],
      engine: e,
      samples: samples,
      placeOf: placeOf,
    );
    expect(near(e.withRole(PlaceRole.home), home), isTrue);
  });

  test('a known Wi-Fi identifies the place even without location', () {
    final e = simulate(monday, 3, officeDay);
    final id = e.addSample(
      LocationSample(ts: DateTime(2026, 10, 9, 10), wifi: 'wifi-work'),
    );
    expect(near(e.byId(id), work), isTrue);
  });

  test('a hotspot carried everywhere is not a reliable fingerprint', () {
    final e = PlaceEngine();
    // The same Wi-Fi seen once in three different places.
    for (final (i, spot) in [home, work, gym].indexed) {
      e.addSample(at(monday, 9 + i, spot, wifiOverride: 'hotspot'));
    }
    for (final p in e.places) {
      expect(p.trustsWifi('hotspot'), isFalse);
    }
  });

  test('user corrections beat inference', () {
    final samples = <LocationSample>[];
    final placeOf = <int?>[];
    final e = simulate(
      monday,
      14,
      officeDay,
      samples: samples,
      placeOf: placeOf,
    );
    final w = e.withRole(PlaceRole.work)!;
    e.block(w.id, PlaceRole.work);
    e.inferRoles(samples, placeOf, DateTime(2026, 10, 18, 23));
    expect(e.withRole(PlaceRole.work), isNull);

    final g = e.places.where((p) => near(p, gym)).single;
    e.setUserRole(g.id, PlaceRole.work);
    e.inferRoles(samples, placeOf, DateTime(2026, 10, 18, 23));
    expect(e.withRole(PlaceRole.work)!.id, g.id);
  });

  test('save and restore', () {
    final e = simulate(monday, 14, officeDay);
    final copy = PlaceEngine.fromJson(e.toJson());
    expect(copy.places.length, e.places.length);
    expect(near(copy.withRole(PlaceRole.home), home), isTrue);
    expect(
      copy.byId(e.withRole(PlaceRole.home)!.id)!.trustsWifi('wifi-home'),
      isTrue,
    );
  });

  test('same Wi-Fi far from its place: location wins', () {
    final e = simulate(monday, 3, officeDay);
    final id = e.addSample(
      at(DateTime(2026, 10, 9), 10, gym, wifiOverride: 'wifi-work'),
    );
    expect(near(e.byId(id), gym), isTrue);
  });
}
