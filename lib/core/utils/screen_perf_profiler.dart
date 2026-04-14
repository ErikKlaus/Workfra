import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Debug-only helper to profile first-frame time and rebuild frequency.
/// Assertions ensure there is zero runtime overhead in release mode.
class ScreenPerfProfiler {
  static final Map<String, int> _buildCounts = <String, int>{};

  static void trackFirstFrame(String screenName) {
    assert(() {
      final stopwatch = Stopwatch()..start();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          '[Perf][$screenName] first-frame ${stopwatch.elapsedMilliseconds}ms',
        );
      });
      return true;
    }());
  }

  static void markBuild(String screenName) {
    assert(() {
      final next = (_buildCounts[screenName] ?? 0) + 1;
      _buildCounts[screenName] = next;

      if (next == 1 || next % 20 == 0) {
        debugPrint('[Perf][$screenName] rebuild count: $next');
      }
      return true;
    }());
  }
}
