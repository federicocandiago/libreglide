/// Cosa mostrare nella card Agenda dello Space.
library;

import 'time_context.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.begin,
    required this.end,
    this.allDay = false,
    this.location,
    this.color,
  });

  factory CalendarEvent.fromMap(Map<Object?, Object?> m) {
    final allDay = (m['allDay'] as bool?) ?? false;
    DateTime time(Object? ms) {
      final t = DateTime.fromMillisecondsSinceEpoch(
        (ms as num).toInt(),
        isUtc: allDay,
      );
      // Gli eventi di tutto il giorno sono salvati a mezzanotte UTC: si
      // riportano alla stessa data nel fuso locale.
      return allDay ? DateTime(t.year, t.month, t.day) : t;
    }

    final location = (m['location'] as String?)?.trim();
    return CalendarEvent(
      id: (m['id'] as num).toInt(),
      title: ((m['title'] as String?) ?? '').trim(),
      begin: time(m['begin']),
      end: time(m['end']),
      allDay: allDay,
      location: location == null || location.isEmpty ? null : location,
      color: (m['color'] as num?)?.toInt(),
    );
  }

  final int id;
  final String title;
  final DateTime begin;
  final DateTime end;
  final bool allDay;
  final String? location;

  /// Colore ARGB del calendario o dell'evento.
  final int? color;
}

enum AgendaDay { today, tomorrow }

class AgendaView {
  const AgendaView(this.day, this.events);
  final AgendaDay day;
  final List<CalendarEvent> events;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Sceglie gli eventi da mostrare:
/// - di giorno, quelli di oggi non ancora finiti;
/// - di sera e di notte, oppure se oggi non resta nulla, quelli di domani.
AgendaView agendaFor(
  DateTime now,
  List<CalendarEvent> events, {
  int max = 4,
  DailyRhythm rhythm = const DailyRhythm(),
}) {
  final today = _dayOf(now);
  final tomorrow = today.add(const Duration(days: 1));

  bool onDay(CalendarEvent e, DateTime day) {
    final next = day.add(const Duration(days: 1));
    // Un evento appartiene al giorno se lo attraversa.
    return e.begin.isBefore(next) && e.end.isAfter(day);
  }

  final remainingToday = [
    for (final e in events)
      if (onDay(e, today) && (e.allDay || e.end.isAfter(now))) e,
  ];
  final slot = slotFor(now, rhythm: rhythm);
  final late = slot == Slot.evening || slot == Slot.night;
  // Dopo mezzanotte, "domani" per l'utente è ancora la giornata che inizia.
  final afterMidnight = now.hour < rhythm.wakeMinute ~/ 60;

  if (afterMidnight) {
    return AgendaView(AgendaDay.today, _sorted(remainingToday, max));
  }
  final timedToday = remainingToday.where((e) => !e.allDay).toList();
  if (late || timedToday.isEmpty && remainingToday.isEmpty) {
    final tomorrowEvents = [
      for (final e in events)
        if (onDay(e, tomorrow)) e,
    ];
    if (late || tomorrowEvents.isNotEmpty) {
      return AgendaView(AgendaDay.tomorrow, _sorted(tomorrowEvents, max));
    }
  }
  return AgendaView(AgendaDay.today, _sorted(remainingToday, max));
}

/// Prima gli eventi di tutto il giorno, poi per ora di inizio.
List<CalendarEvent> _sorted(List<CalendarEvent> list, int max) {
  final sorted = [...list]
    ..sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return a.begin.compareTo(b.begin);
    });
  return sorted.take(max).toList();
}

/// Prossimo impegno con un luogo che inizia entro [window] (o è già
/// iniziato e non ancora finito): la "prossima destinazione".
CalendarEvent? nextDestination(
  DateTime now,
  List<CalendarEvent> events, {
  Duration window = const Duration(hours: 3),
}) {
  final candidates = [
    for (final e in events)
      if (!e.allDay &&
          e.location != null &&
          e.end.isAfter(now) &&
          e.begin.isBefore(now.add(window)))
        e,
  ]..sort((a, b) => a.begin.compareTo(b.begin));
  return candidates.isEmpty ? null : candidates.first;
}
