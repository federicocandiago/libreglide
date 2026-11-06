/// Statistiche sui frame, scritte nel logcat (tag `flutter`, prefisso
/// `LGPERF`). Attive solo se l'app è compilata con
/// `--dart-define=LIBREGLIDE_PERF=true`; altrimenti non costano nulla.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/scheduler.dart';

const bool perfLoggingEnabled = bool.fromEnvironment('LIBREGLIDE_PERF');

class FrameStats {
  FrameStats._();

  static final List<FrameTiming> _buffer = [];
  static Timer? _timer;

  static void start() {
    if (!perfLoggingEnabled) return;
    SchedulerBinding.instance.addTimingsCallback(_buffer.addAll);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _flush());
  }

  static void stop() {
    _timer?.cancel();
  }

  static double _p(List<double> sorted, double q) {
    if (sorted.isEmpty) return 0;
    final i = ((sorted.length - 1) * q).round();
    return sorted[i];
  }

  static void _flush() {
    if (_buffer.isEmpty) return;
    final views = PlatformDispatcher.instance.views;
    final hz = views.isEmpty ? 60.0 : views.first.display.refreshRate;
    final budget = 1000 / hz;

    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final t in _buffer) ms(t.buildDuration)]..sort();
    final raster = [for (final t in _buffer) ms(t.rasterDuration)]..sort();
    final total = [for (final t in _buffer) ms(t.totalSpan)]..sort();
    final jank = [
      for (final t in _buffer)
        if (math.max(ms(t.buildDuration), ms(t.rasterDuration)) > budget) t,
    ].length;

    // ignore: avoid_print
    print(
      'LGPERF frames=${_buffer.length} hz=${hz.toStringAsFixed(0)} '
      'budget=${budget.toStringAsFixed(1)} '
      'build_p50=${_p(build, .5).toStringAsFixed(1)} '
      'build_p90=${_p(build, .9).toStringAsFixed(1)} '
      'build_max=${build.last.toStringAsFixed(1)} '
      'raster_p50=${_p(raster, .5).toStringAsFixed(1)} '
      'raster_p90=${_p(raster, .9).toStringAsFixed(1)} '
      'raster_max=${raster.last.toStringAsFixed(1)} '
      'total_p90=${_p(total, .9).toStringAsFixed(1)} '
      'jank=$jank',
    );
    _buffer.clear();
  }
}
