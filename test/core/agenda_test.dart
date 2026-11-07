import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/agenda.dart';

void main() {
  final day = DateTime(2026, 11, 5);
  CalendarEvent ev(int id, DateTime b, DateTime e, {bool allDay = false}) =>
      CalendarEvent(id: id, title: 'E$id', begin: b, end: e, allDay: allDay);
  DateTime at(int d, int h, [int m = 0]) =>
      DateTime(day.year, day.month, day.day + d, h, m);

  final morningMeeting = ev(1, at(0, 9), at(0, 10));
  final afternoonCall = ev(2, at(0, 15), at(0, 16));
  final allDayToday = ev(3, at(0, 0), at(1, 0), allDay: true);
  final tomorrowBreakfast = ev(4, at(1, 8), at(1, 9));
  final events = [
    morningMeeting,
    afternoonCall,
    allDayToday,
    tomorrowBreakfast,
  ];

  test(
    'daytime: unfinished events of today, all-day ones first',
    () {
      final v = agendaFor(at(0, 11), events);
      expect(v.day, AgendaDay.today);
      expect([for (final e in v.events) e.id], [3, 2]);
    },
  );

  test('evening: events of tomorrow', () {
    final v = agendaFor(at(0, 20), events);
    expect(v.day, AgendaDay.tomorrow);
    expect([for (final e in v.events) e.id], [4]);
  });

  test('evening with no events tomorrow: empty tomorrow', () {
    final v = agendaFor(at(0, 20), [morningMeeting]);
    expect(v.day, AgendaDay.tomorrow);
    expect(v.events, isEmpty);
  });

  test('daytime, all done today: moves to tomorrow if it has events', () {
    final v = agendaFor(at(0, 17), [morningMeeting, tomorrowBreakfast]);
    expect(v.day, AgendaDay.tomorrow);
    expect([for (final e in v.events) e.id], [4]);
  });

  test("after midnight: the day just started is still 'today'", () {
    final v = agendaFor(at(1, 1), events);
    expect(v.day, AgendaDay.today);
    expect([for (final e in v.events) e.id], [4]);
  });

  test('all-day event stored at midnight UTC', () {
    final utcMidnight = DateTime.utc(2026, 11, 6).millisecondsSinceEpoch;
    final e = CalendarEvent.fromMap({
      'id': 9,
      'title': ' Festa ',
      'begin': utcMidnight,
      'end': utcMidnight + 86400000,
      'allDay': true,
      'location': '  ',
    });
    expect(e.begin, DateTime(2026, 11, 6));
    expect(e.title, 'Festa');
    expect(e.location, isNull);
  });

  group('next destination', () {
    CalendarEvent at3(int id, int h, {String? loc, bool allDay = false}) =>
        CalendarEvent(
          id: id,
          title: 'E$id',
          begin: at(0, h),
          end: at(0, h + 1),
          allDay: allDay,
          location: loc,
        );

    test('the first one with a location within 3 hours', () {
      final events = [
        at3(1, 12),
        at3(2, 13, loc: 'Ufficio'),
        at3(3, 14, loc: 'Palestra'),
      ];
      expect(nextDestination(at(0, 11), events)?.id, 2);
    });

    test('too far ahead or without location: none', () {
      expect(nextDestination(at(0, 8), [at3(2, 13, loc: 'Ufficio')]), isNull);
      expect(nextDestination(at(0, 12), [at3(1, 13)]), isNull);
    });

    test('already started but not finished: still valid', () {
      final e = at3(5, 10, loc: 'Sala');
      expect(nextDestination(at(0, 10, 30), [e])?.id, 5);
      expect(nextDestination(at(0, 11, 30), [e]), isNull);
    });
  });
}
