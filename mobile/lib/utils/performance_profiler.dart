import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A utility for profiling specific code blocks
class PerformanceProfiler {
  static PerformanceProfiler? _instance;
  static PerformanceProfiler get instance => _instance ??= PerformanceProfiler._();
  
  PerformanceProfiler._();

  final Map<String, _ProfileData> _activeProfiles = {};
  final Map<String, List<Duration>> _completedProfiles = {};
  final Map<String, int> _callCounts = {};

  /// Start profiling a named block
  void startProfile(String name) {
    _activeProfiles[name] = _ProfileData(
      startTime: DateTime.now(),
      startMemory: 0, // Would need platform channel for accurate memory
    );
  }

  /// Stop profiling and record the result
  Duration? stopProfile(String name) {
    final profile = _activeProfiles.remove(name);
    if (profile == null) {
      if (kDebugMode) {
        developer.log('No active profile found for: $name', name: 'Profiler');
      }
      return null;
    }

    final duration = DateTime.now().difference(profile.startTime);
    
    // Store result
    _completedProfiles.putIfAbsent(name, () => []).add(duration);
    _callCounts[name] = (_callCounts[name] ?? 0) + 1;
    
    // Log if slow
    if (kDebugMode && duration.inMilliseconds > 100) {
      developer.log(
        'Slow profile "$name": ${duration.inMilliseconds}ms',
        name: 'Profiler',
        level: 800,
      );
    }

    return duration;
  }

  /// Profile a function execution
  T profile<T>(String name, T Function() fn) {
    startProfile(name);
    try {
      return fn();
    } finally {
      stopProfile(name);
    }
  }

  /// Profile an async function execution
  Future<T> profileAsync<T>(String name, Future<T> Function() fn) async {
    startProfile(name);
    try {
      return await fn();
    } finally {
      stopProfile(name);
    }
  }

  /// Get statistics for a profile
  ProfileStats? getStats(String name) {
    final durations = _completedProfiles[name];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    
    // Calculate p95
    final sorted = durations.map((d) => d.inMilliseconds).toList()..sort();
    final p95Index = (sorted.length * 0.95).floor();
    final p95Ms = sorted.isNotEmpty ? sorted[p95Index.clamp(0, sorted.length - 1)] : 0;

    return ProfileStats(
      name: name,
      callCount: _callCounts[name] ?? durations.length,
      totalTimeMs: totalMs,
      avgTimeMs: avgMs,
      minTimeMs: minMs,
      maxTimeMs: maxMs,
      p95TimeMs: p95Ms,
    );
  }

  /// Get all profile stats
  Map<String, ProfileStats> getAllStats() {
    final stats = <String, ProfileStats>{};
    for (final name in _completedProfiles.keys) {
      final s = getStats(name);
      if (s != null) {
        stats[name] = s;
      }
    }
    return stats;
  }

  /// Log all statistics
  void logAllStats() {
    if (!kDebugMode) return;

    final stats = getAllStats();
    if (stats.isEmpty) {
      developer.log('No profiling data available', name: 'Profiler');
      return;
    }

    // Sort by total time
    final sorted = stats.values.toList()
      ..sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

    final buffer = StringBuffer();
    buffer.writeln('╔═══════════════════════════════════════════════════════════════╗');
    buffer.writeln('║                    PROFILING STATISTICS                       ║');
    buffer.writeln('╠═══════════════════════════════════════════════════════════════╣');
    buffer.writeln('║ Name                    │ Calls │ Avg    │ P95    │ Total    ║');
    buffer.writeln('╠═══════════════════════════════════════════════════════════════╣');
    
    for (final stat in sorted.take(10)) {
      buffer.writeln(
        '║ ${stat.name.padRight(24)}│ ${stat.callCount.toString().padLeft(5)} │ ${stat.avgTimeMs.toStringAsFixed(0).padLeft(5)}ms │ ${stat.p95TimeMs.toString().padLeft(5)}ms │ ${stat.totalTimeMs.toString().padLeft(6)}ms ║'
      );
    }
    
    buffer.writeln('╚═══════════════════════════════════════════════════════════════╝');
    
    developer.log(buffer.toString(), name: 'Profiler');
  }

  /// Reset all profiling data
  void reset() {
    _activeProfiles.clear();
    _completedProfiles.clear();
    _callCounts.clear();
    
    if (kDebugMode) {
      developer.log('Profiler data reset', name: 'Profiler');
    }
  }

  /// Check for potential memory leaks (profiles not stopped)
  List<String> checkForLeaks() {
    return _activeProfiles.keys.toList();
  }
}

/// Profile data for a single execution
class _ProfileData {
  final DateTime startTime;
  final int startMemory;

  _ProfileData({
    required this.startTime,
    required this.startMemory,
  });
}

/// Statistics for a profiled operation
class ProfileStats {
  final String name;
  final int callCount;
  final int totalTimeMs;
  final double avgTimeMs;
  final int minTimeMs;
  final int maxTimeMs;
  final int p95TimeMs;

  ProfileStats({
    required this.name,
    required this.callCount,
    required this.totalTimeMs,
    required this.avgTimeMs,
    required this.minTimeMs,
    required this.maxTimeMs,
    required this.p95TimeMs,
  });

  @override
  String toString() => 
    'ProfileStats($name: avg=${avgTimeMs.toStringAsFixed(1)}ms, '
    'p95=${p95TimeMs}ms, calls=$callCount)';
}

/// Widget profiling mixin for automatic widget build timing
mixin WidgetProfiler<T extends StatefulWidget> on State<T> {
  String get profilerName => T.toString();
  bool _profilerInitialized = false;

  @override
  void initState() {
    super.initState();
    PerformanceProfiler.instance.startProfile('$profilerName initState');
    // Defer stop to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceProfiler.instance.stopProfile('$profilerName initState');
    });
  }

  @override
  Widget build(BuildContext context) {
    PerformanceProfiler.instance.startProfile('$profilerName build');
    final widget = _profiledBuild(context);
    PerformanceProfiler.instance.stopProfile('$profilerName build');
    return widget;
  }

  Widget _profiledBuild(BuildContext context);
}

/// Extension for easy profiling on Future
extension FutureProfiler<T> on Future<T> {
  Future<T> profile(String name) {
    PerformanceProfiler.instance.startProfile(name);
    return then((result) {
      PerformanceProfiler.instance.stopProfile(name);
      return result;
    }).catchError((error) {
      PerformanceProfiler.instance.stopProfile(name);
      throw error;
    });
  }
}

/// Extension for easy profiling on Stopwatch
extension StopwatchProfiler on Stopwatch {
  Duration profile(String name) {
    start();
    final result = elapsed;
    stop();
    PerformanceProfiler.instance.startProfile(name);
    // Return a wrapper that stops the profiler
    return result;
  }
}
