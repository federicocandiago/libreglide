import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Sonda di sviluppo: tempi dei frame (comandi `perf:start` e `perf:report`).
/// Il riepilogo va nel log di sistema (tag flutter).
class PerfProbe {
  static final List<FrameTiming> _frames = [];
  static bool _on = false;

  static void start() {
    _frames.clear();
    if (!_on) {
      _on = true;
      SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
    }
  }

  static void report(String label) {
    if (_frames.isEmpty) {
      debugPrint('libreglide-perf $label: nessun frame');
      return;
    }
    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = [for (final f in _frames) ms(f.buildDuration)]..sort();
    final raster = [for (final f in _frames) ms(f.rasterDuration)]..sort();
    final total = [for (final f in _frames) ms(f.totalSpan)]..sort();
    String stats(List<double> v) =>
        'media ${(v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1)} '
        'p90 ${v[(v.length * 0.9).floor()].toStringAsFixed(1)} '
        'max ${v.last.toStringAsFixed(1)}';
    final budget = 1000 / 90;
    final slow = [
      for (final f in _frames)
        if (ms(f.buildDuration) > budget || ms(f.rasterDuration) > budget) f,
    ].length;
    // Cadenza reale: intervallo tra i vsync di frame consecutivi (solo
    // dentro le animazioni, sotto i 50 ms).
    final gaps = <double>[];
    for (var i = 1; i < _frames.length; i++) {
      final g =
          (_frames[i].timestampInMicroseconds(FramePhase.vsyncStart) -
              _frames[i - 1].timestampInMicroseconds(FramePhase.vsyncStart)) /
          1000;
      if (g > 0 && g < 50) gaps.add(g);
    }
    gaps.sort();
    final at90 = gaps.where((g) => g < 13).length;
    final at60 = gaps.where((g) => g >= 13 && g < 20).length;
    debugPrint(
      'libreglide-perf $label: cadenza mediana '
      '${gaps.isEmpty ? '-' : gaps[gaps.length ~/ 2].toStringAsFixed(1)} ms, '
      '~90Hz $at90, ~60Hz $at60, più lenti ${gaps.length - at90 - at60}',
    );
    debugPrint(
      'libreglide-perf $label: frame ${_frames.length}, lenti $slow | '
      'build ${stats(build)} | raster ${stats(raster)} | '
      'totale ${stats(total)}',
    );
    _frames.clear();
  }
}
