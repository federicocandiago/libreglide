/// Digital detox: quando il blocco delle app è attivo.
library;

/// Orario del detox: tutto il giorno oppure una fascia (anche a cavallo
/// della mezzanotte). I minuti partono dalla mezzanotte.
class DetoxSchedule {
  const DetoxSchedule({
    required this.allDay,
    required this.start,
    required this.end,
  });

  final bool allDay;
  final int start;
  final int end;

  bool isActiveAt(DateTime t) {
    if (allDay || start == end) return true;
    final now = t.hour * 60 + t.minute;
    return start < end ? now >= start && now < end : now >= start || now < end;
  }

  /// Il prossimo istante in cui lo stato cambia (null se non cambia mai).
  DateTime? nextChange(DateTime t) {
    if (allDay || start == end) return null;
    final midnight = DateTime(t.year, t.month, t.day);
    final now = t.hour * 60 + t.minute;
    var best = 24 * 60 * 2;
    for (final m in [start, end]) {
      final d = m > now ? m - now : m + 24 * 60 - now;
      if (d < best) best = d;
    }
    return midnight.add(Duration(minutes: now + best));
  }
}

/// Un PIN valido: da 8 a 16 caratteri.
bool validDetoxPin(String pin) => pin.length >= 8 && pin.length <= 16;
