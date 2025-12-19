import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Lightweight startup tracing helper for debug builds.
class StartupTrace {
  StartupTrace._();

  static int? _t0Micros;
  static bool _printed = false;
  static bool _postFrameHooked = false;
  static final Map<String, int> _marks = <String, int>{};

  static bool get _enabled => !kReleaseMode;

  /// Capture the very first timestamp in `main()`.
  static void start() {
    if (!_enabled || _t0Micros != null) return;
    final now = DateTime.now().microsecondsSinceEpoch;
    _t0Micros = now;
    _marks['t0'] = now;
  }

  /// Generic marker for future extension points.
  static void mark(String name) {
    if (!_enabled || _t0Micros == null || _marks.containsKey(name)) return;
    _marks[name] = DateTime.now().microsecondsSinceEpoch;
    if (name == 'firstFrame') {
      _printSummary();
    }
  }

  static void markRunApp() => mark('runApp');

  static void markFirstBuild() => mark('firstBuild');

  static void markFirstFrame() => mark('firstFrame');

  /// Hook into the first post-frame callback for first-frame timing.
  static void scheduleFirstFrameHook() {
    if (!_enabled || _postFrameHooked) return;
    _postFrameHooked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markFirstFrame();
    });
  }

  static int? _delayFromT0(String key) {
    final t0 = _t0Micros;
    final t = _marks[key];
    if (t0 == null || t == null) return null;
    return t - t0;
  }

  static void _printSummary() {
    if (_printed) return;
    _printed = true;
    final t0 = _t0Micros;
    if (t0 == null) return;
    final runAppDelay = _delayFromT0('runApp');
    final firstBuildDelay = _delayFromT0('firstBuild');
    final firstFrameDelay = _delayFromT0('firstFrame');
    final buffer = StringBuffer('[StartupTrace] ')
      ..write('t0=$t0 ')
      ..write('runApp=${_formatDelay(runAppDelay)} ')
      ..write('firstBuild=${_formatDelay(firstBuildDelay)} ')
      ..write('firstFrame=${_formatDelay(firstFrameDelay)} ')
      ..write('(ms)');
    debugPrint(buffer.toString());
  }

  static String _formatDelay(int? microseconds) {
    if (microseconds == null) return 'NA';
    return (microseconds / 1000).toStringAsFixed(1);
  }
}
