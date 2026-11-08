import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/exercise.dart';

void main() {
  final t0 = DateTime(2026, 11, 8, 18);
  DateTime at(int minutes) => t0.add(Duration(minutes: minutes));

  test('a run between two launcher visits is exercise', () {
    final d = ExerciseDetector();
    expect(d.add(StepSample(1000, at(0))), isFalse);
    // 20 minutes at 155 steps per minute.
    expect(d.add(StepSample(1000 + 3100, at(20))), isTrue);
    expect(d.lastCadence, closeTo(155, 0.1));
  });

  test('an ordinary walk is not', () {
    final d = ExerciseDetector()..add(StepSample(0, at(0)));
    expect(d.add(StepSample(900, at(10))), isFalse); // 90 steps/min
  });

  test('exercise holds for a while, then ends', () {
    final d = ExerciseDetector()..add(StepSample(0, at(0)));
    expect(d.add(StepSample(2400, at(15))), isTrue);
    // Readings too close to evaluate keep the state.
    expect(d.add(StepSample(2450, at(16))), isTrue);
    // Held without new evidence, then over.
    expect(d.activeAt(at(29)), isTrue);
    expect(d.activeAt(at(31)), isFalse);
  });

  test('resting right after ends it at once', () {
    final d = ExerciseDetector()..add(StepSample(0, at(0)));
    expect(d.add(StepSample(2400, at(15))), isTrue);
    expect(d.add(StepSample(2500, at(25))), isFalse); // 10 steps/min
  });

  test('long gaps and reboots restart the anchor', () {
    final d = ExerciseDetector()..add(StepSample(5000, at(0)));
    // 2 hours later: too long to say anything about now.
    expect(d.add(StepSample(20000, at(120))), isFalse);
    expect(d.lastCadence, isNull);
    // Reboot: the counter starts again from a lower value.
    expect(d.add(StepSample(300, at(130))), isFalse);
    expect(d.add(StepSample(300 + 1600, at(140))), isTrue);
  });
}
