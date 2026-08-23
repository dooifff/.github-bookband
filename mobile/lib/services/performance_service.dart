import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance metrics data class
class PerformanceMetrics {
  final double fps;
  final Duration平均FrameTime;
  final int missedFrames;
  final double memoryUsageMB;
  final int gpuCacheBytes;
  final Duration startupTime;
  final Map<String, Duration> screenLoadTimes;
  final int totalScreenLoads;

  PerformanceMetrics({
    required this.fps,
    required this平均FrameTime,
    required this.missedFrames,
    required this.memoryUsageMB,
    required this.gpuCacheBytes,
    required this.startupTime,
    required this.screenLoadTimes,
    required this.totalScreenLoads,
  });

  Map<String, dynamic> toJson() => {
    'fps': fps,
    'avg_frame_time_ms': 平均FrameTime.inMilliseconds,
    'missed_frames': missedFrames,
    'memory_usage_mb': memoryUsageMB,
    'gpu_cache_bytes': gpuCacheBytes,
    'startup_time_ms': startupTime.inMilliseconds,
    'screen_load_times': screenLoadTimes.map((k, v) => MapEntry(k, v.inMilliseconds)),
    'total_screen_loads': totalScreenLoads,
  };
}

/// Performance monitoring service for Flutter apps
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance => _instance ??= PerformanceService._();
  
  PerformanceService._();

  // Frame metrics
  int _frameCount = 0;
  int _missedFrames = 0;
  Duration _totalFrameTime = Duration.zero;
  DateTime? _lastFrameTime;
  
  // Memory tracking
  double _memoryUsageMB = 0;
  Timer? _memoryTimer;
  
  // Screen load tracking
  final Map<String, Stopwatch> _screenTimers = {};
  final Map<String, Duration> _screenLoadTimes = {};
  int _totalScreenLoads = 0;
  
  // Startup time
  DateTime? _appStartTime;
  Duration _startupTime = Duration.zero;
  bool _isInitialized = false;
  
  // FPS calculation
  double _currentFPS = 0;
  int _framesInLastSecond = 0;
  Timer? _fpsTimer;

  /// Initialize performance monitoring
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _appStartTime = DateTime.now();
    
    // Start FPS monitoring
    _startFPSMonitoring();
    
    // Start memory monitoring
    _startMemoryMonitoring();
    
    // Add frame callback
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    
    if (kDebugMode) {
      developer.log('PerformanceService initialized', name: 'Performance');
    }
  }

  /// Start FPS monitoring
  void _startFPSMonitoring() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentFPS = _framesInLastSecond.toDouble();
      _framesInLastSecond = 0;
      
      if (kDebugMode && _currentFPS < 30) {
        developer.log(
          'Low FPS detected: ${_currentFPS.toStringAsFixed(1)}',
          name: 'Performance',
          level: 900,
        );
      }
    });
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateMemoryUsage();
    });
  }

  /// Update memory usage
  void _updateMemoryUsage() {
    try {
      // Get current process info
      final info = ProcessInfo.current;
      _memoryUsageMB = info.maxRss / (1024 * 1024); // Convert to MB
    } catch (e) {
      // Fallback - use Flutter's memory info
      if (kDebugMode) {
        developer.log('Could not get memory info: $e', name: 'Performance');
      }
    }
  }

  /// Handle frame timings
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      final totalDuration = buildDuration + rasterDuration;
      
      _frameCount++;
      _framesInLastSecond++;
      _totalFrameTime += totalDuration;
      
      // Check for jank (frames > 16ms)
      if (totalDuration > const Duration(milliseconds: 16)) {
        _missedFrames++;
        
        if (kDebugMode && totalDuration > const Duration(milliseconds: 32)) {
          developer.log(
            'Jank detected: ${totalDuration.inMilliseconds}ms '
            '(build: ${buildDuration.inMilliseconds}ms, '
            'raster: ${rasterDuration.inMilliseconds}ms)',
            name: 'Performance',
            level: 900,
          );
        }
      }
    }
  }

  /// Start tracking screen load time
  void startScreenLoad(String screenName) {
    _screenTimers[screenName] = Stopwatch()..start();
    _totalScreenLoads++;
  }

  /// Stop tracking screen load time
  Duration stopScreenLoad(String screenName) {
    final timer = _screenTimers.remove(screenName);
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsed;
      _screenLoadTimes[screenName] = duration;
      
      if (kDebugMode) {
        developer.log(
          'Screen "$screenName" loaded in ${duration.inMilliseconds}ms',
          name: 'Performance',
        );
      }
      
      return duration;
    }
    return Duration.zero;
  }

  /// Mark app as fully loaded
  void markAppLoaded() {
    if (_appStartTime != null) {
      _startupTime = DateTime.now().difference(_appStartTime!);
      
      if (kDebugMode) {
        developer.log(
          'App startup time: ${_startupTime.inMilliseconds}ms',
          name: 'Performance',
        );
      }
    }
  }

  /// Get current FPS
  double get currentFPS => _currentFPS;

  /// Get current metrics
  PerformanceMetrics getMetrics() {
    final avgFrameTime = _frameCount > 0
        ? Duration(milliseconds: (_totalFrameTime.inMilliseconds / _frameCount).round())
        : Duration.zero;

    return PerformanceMetrics(
      fps: _currentFPS,
      平均FrameTime: avgFrameTime,
      missedFrames: _missedFrames,
      memoryUsageMB: _memoryUsageMB,
      gpuCacheBytes: 0, // Would need platform channel for accurate GPU cache
      startupTime: _startupTime,
      screenLoadTimes: Map.from(_screenLoadTimes),
      totalScreenLoads: _totalScreenLoads,
    );
  }

  /// Get FPS rating
  String getFPSRating() {
    if (_currentFPS >= 55) return 'Excellent';
    if (_currentFPS >= 45) return 'Good';
    if (_currentFPS >= 30) return 'Fair';
    return 'Poor';
  }

  /// Get frame drop percentage
  double getFrameDropPercentage() {
    if (_frameCount == 0) return 0;
    return (_missedFrames / _frameCount) * 100;
  }

  /// Reset metrics
  void resetMetrics() {
    _frameCount = 0;
    _missedFrames = 0;
    _totalFrameTime = Duration.zero;
    _screenLoadTimes.clear();
    _totalScreenLoads = 0;
    
    if (kDebugMode) {
      developer.log('Performance metrics reset', name: 'Performance');
    }
  }

  /// Dispose resources
  void dispose() {
    _fpsTimer?.cancel();
    _memoryTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _isInitialized = false;
  }

  /// Log performance summary
  void logSummary() {
    if (!kDebugMode) return;
    
    final metrics = getMetrics();
    
    developer.log('''
╔══════════════════════════════════════════════════╗
║         PERFORMANCE SUMMARY                      ║
╠══════════════════════════════════════════════════╣
║ FPS: ${metrics.fps.toStringAsFixed(1).padLeft(6)} (${getFPSRating().padRight(10)})     ║
║ Avg Frame Time: ${metrics.平均FrameTime.inMilliseconds.toString().padLeft(4)}ms                    ║
║ Missed Frames: ${metrics.missedFrames.toString().padLeft(6)} (${getFrameDropPercentage().toStringAsFixed(1)}%)        ║
║ Memory: ${metrics.memoryUsageMB.toStringAsFixed(1).padLeft(6)}MB                       ║
║ Startup: ${metrics.startupTime.inMilliseconds.toString().padLeft(6)}ms                    ║
║ Screen Loads: ${metrics.totalScreenLoads.toString().padLeft(4)}                           ║
╚══════════════════════════════════════════════════╝
''', name: 'Performance');
  }
}
