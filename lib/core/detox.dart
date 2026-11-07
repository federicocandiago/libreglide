/// Digital detox: when app blocking is active.
library;

/// Detox schedule: all day or a time window (possibly spanning midnight).
/// Minutes are counted from midnight.
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

  /// The next instant the state changes (null if it never changes).
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

/// A valid PIN: 8 to 16 characters.
bool validDetoxPin(String pin) => pin.length >= 8 && pin.length <= 16;
