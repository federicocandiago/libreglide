import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/detox.dart';

void main() {
  test('all day is always active', () {
    const s = DetoxSchedule(allDay: true, start: 0, end: 0);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 3)), isTrue);
    expect(s.nextChange(DateTime(2026, 11, 5, 3)), isNull);
  });

  test('window within the same day', () {
    const s = DetoxSchedule(allDay: false, start: 9 * 60, end: 18 * 60);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 8, 59)), isFalse);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 9)), isTrue);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 17, 59)), isTrue);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 18)), isFalse);
  });

  test('window spanning midnight', () {
    const s = DetoxSchedule(allDay: false, start: 22 * 60, end: 7 * 60);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 23)), isTrue);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 6, 59)), isTrue);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 7)), isFalse);
    expect(s.isActiveAt(DateTime(2026, 11, 5, 21, 59)), isFalse);
    expect(
      s.nextChange(DateTime(2026, 11, 5, 23, 30)),
      DateTime(2026, 11, 6, 7),
    );
    expect(s.nextChange(DateTime(2026, 11, 5, 12)), DateTime(2026, 11, 5, 22));
  });

  test('PIN of 8 to 16 characters', () {
    expect(validDetoxPin('1234567'), isFalse);
    expect(validDetoxPin('12345678'), isTrue);
    expect(validDetoxPin('a' * 16), isTrue);
    expect(validDetoxPin('a' * 17), isFalse);
  });
}
