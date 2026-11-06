import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/time_context.dart';

void main() {
  DateTime at(int h, int m) => DateTime(2026, 11, 5, h, m); // giovedì

  group('slotFor (risveglio 07:00, sonno 23:00)', () {
    test('confini delle fasce', () {
      expect(slotFor(at(6, 59)), Slot.night);
      expect(slotFor(at(7, 0)), Slot.wakeUp);
      expect(slotFor(at(8, 59)), Slot.wakeUp);
      expect(slotFor(at(9, 0)), Slot.morning);
      expect(slotFor(at(11, 59)), Slot.morning);
      expect(slotFor(at(12, 0)), Slot.lunch);
      expect(slotFor(at(14, 29)), Slot.lunch);
      expect(slotFor(at(14, 30)), Slot.afternoon);
      expect(slotFor(at(18, 59)), Slot.afternoon);
      expect(slotFor(at(19, 0)), Slot.evening);
      expect(slotFor(at(21, 59)), Slot.evening);
      expect(slotFor(at(22, 0)), Slot.night);
      expect(slotFor(at(0, 30)), Slot.night);
    });

    test('sonno dopo mezzanotte: la sera arriva fino a mezzanotte', () {
      const rhythm = DailyRhythm(wakeMinute: 8 * 60, sleepMinute: 60);
      expect(slotFor(at(23, 30), rhythm: rhythm), Slot.evening);
      expect(slotFor(at(0, 30), rhythm: rhythm), Slot.night);
      expect(slotFor(at(8, 30), rhythm: rhythm), Slot.wakeUp);
    });
  });

  group('festività italiane', () {
    test('Pasqua', () {
      expect(easterSunday(2024), DateTime(2024, 3, 31));
      expect(easterSunday(2025), DateTime(2025, 4, 20));
      expect(easterSunday(2026), DateTime(2026, 4, 5));
    });

    test('Pasquetta e date fisse', () {
      expect(isPublicHoliday(DateTime(2026, 4, 6)), isTrue);
      expect(isPublicHoliday(DateTime(2026, 4, 25)), isTrue);
      expect(isPublicHoliday(DateTime(2026, 12, 8)), isTrue);
      expect(isPublicHoliday(DateTime(2026, 11, 5)), isFalse);
    });

    test('San Francesco dal 2026', () {
      expect(isPublicHoliday(DateTime(2025, 10, 4)), isFalse);
      expect(isPublicHoliday(DateTime(2026, 10, 4)), isTrue);
    });

    test('tipo di giorno', () {
      expect(dayTypeFor(DateTime(2026, 11, 5)), DayType.workday);
      expect(dayTypeFor(DateTime(2026, 11, 7)), DayType.holiday); // sabato
      expect(
        dayTypeFor(DateTime(2026, 6, 2)),
        DayType.holiday,
      ); // martedì festivo
    });
  });

  test('la chiave del contesto cambia con la fascia', () {
    final a = ContextFeatures.at(at(10, 0));
    final b = ContextFeatures.at(at(10, 30));
    final c = ContextFeatures.at(at(13, 0));
    expect(a.key, b.key);
    expect(a.key, isNot(c.key));
  });
}
