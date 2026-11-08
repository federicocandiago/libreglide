/// Exercise detection from the system step counter (spec-motore-contesto
/// §3, `steps`).
///
/// No background service and no accelerometer: Android's step counter is a
/// low-power hardware counter (steps since boot) that the phone keeps
/// anyway. libreGLIDE only reads it when the user comes back to the
/// launcher and compares it with the previous reading: the average cadence
/// in between tells whether they were running or walking briskly.
library;

/// A step counter reading.
class StepSample {
  const StepSample(this.steps, this.at);

  /// Steps since boot.
  final int steps;
  final DateTime at;
}

class ExerciseDetector {
  ExerciseDetector({
    this.activeCadence = 115,
    this.restCadence = 60,
    this.minWindow = const Duration(minutes: 3),
    this.maxWindow = const Duration(minutes: 45),
    this.holdFor = const Duration(minutes: 15),
  });

  /// Steps per minute at or above which the window counts as exercise
  /// (brisk walking is about 115, running 150+).
  final double activeCadence;

  /// Steps per minute below which exercise is over.
  final double restCadence;

  /// Shorter windows are too noisy: the reading is kept as the anchor
  /// until enough time has passed.
  final Duration minWindow;

  /// Longer windows dilute the cadence and say little about now: the
  /// anchor restarts.
  final Duration maxWindow;

  /// How long the Space stays after exercise was detected, without newer
  /// evidence.
  final Duration holdFor;

  StepSample? _anchor;
  DateTime? _activeUntil;

  /// Cadence of the last evaluated window, for diagnostics.
  double? lastCadence;

  /// Whether the user is exercising at [now].
  bool activeAt(DateTime now) =>
      _activeUntil != null && now.isBefore(_activeUntil!);

  /// Adds a reading and returns whether the user is exercising.
  bool add(StepSample s) {
    final anchor = _anchor;
    if (anchor == null || s.steps < anchor.steps) {
      // First reading, or the counter restarted after a reboot.
      _anchor = s;
      return activeAt(s.at);
    }
    final window = s.at.difference(anchor.at);
    if (window < minWindow) return activeAt(s.at);
    _anchor = s;
    if (window > maxWindow) return activeAt(s.at);
    final cadence = (s.steps - anchor.steps) / (window.inSeconds / 60);
    lastCadence = cadence;
    if (cadence >= activeCadence) {
      _activeUntil = s.at.add(holdFor);
    } else if (cadence < restCadence) {
      _activeUntil = null;
    }
    return activeAt(s.at);
  }

  void reset() {
    _anchor = null;
    _activeUntil = null;
    lastCadence = null;
  }
}
