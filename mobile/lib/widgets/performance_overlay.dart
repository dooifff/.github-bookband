import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/performance_service.dart';

/// A floating performance overlay widget for debugging
class PerformanceOverlay extends StatefulWidget {
  final bool initialVisible;
  final Offset initialPosition;

  const PerformanceOverlay({
    super.key,
    this.initialVisible = false,
    this.initialPosition = const Offset(10, 100),
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isVisible = false;
  bool _isExpanded = false;
  Offset _position = Offset.zero;
  PerformanceMetrics? _metrics;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initialVisible;
    _position = widget.initialPosition;
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isVisible && mounted) {
        setState(() {
          _metrics = PerformanceService.instance.getMetrics();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _animationController.forward();
        _metrics = PerformanceService.instance.getMetrics();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(double mb) {
    if (mb < 100) return Colors.green;
    if (mb < 200) return Colors.yellow;
    if (mb < 300) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Toggle button
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            onTap: _toggleVisibility,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isVisible ? (_isExpanded ? 200 : 60) : 60,
              height: _isVisible ? (_isExpanded ? 280 : 60) : 60,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isVisible ? _buildExpandedContent() : _buildCollapsedButton(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedButton() {
    final fps = _metrics?.fps ?? 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            color: _getFPSColor(fps),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            '${fps.toStringAsFixed(0)}',
            style: TextStyle(
              color: _getFPSColor(fps),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    final metrics = _metrics;
    if (metrics == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PERF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleExpanded,
                    child: Icon(
                      _isExpanded ? Icons.compress : Icons.expand,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _toggleVisibility,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 8),
          
          // FPS
          _buildMetricRow(
            'FPS',
            '${metrics.fps.toStringAsFixed(1)}',
            _getFPSColor(metrics.fps),
          ),
          
          // Frame Time
          _buildMetricRow(
            'Frame',
            '${metrics.averageFrameTime.inMilliseconds}ms',
            metrics.averageFrameTime.inMilliseconds > 16 ? Colors.orange : Colors.green,
          ),
          
          // Missed Frames
          _buildMetricRow(
            'Dropped',
            '${metrics.missedFrames}',
            metrics.missedFrames > 10 ? Colors.red : Colors.green,
          ),
          
          const Divider(color: Colors.white24, height: 8),
          
          // Memory
          _buildMetricRow(
            'Memory',
            '${metrics.memoryUsageMB.toStringAsFixed(1)}MB',
            _getMemoryColor(metrics.memoryUsageMB),
          ),
          
          // Startup Time
          _buildMetricRow(
            'Startup',
            '${metrics.startupTime.inMilliseconds}ms',
            metrics.startupTime.inMilliseconds > 2000 ? Colors.orange : Colors.green,
          ),
          
          const Divider(color: Colors.white24, height: 8),
          
          // Screen Loads
          _buildMetricRow(
            'Screens',
            '${metrics.totalScreenLoads}',
            Colors.white,
          ),
          
          // Top slow screens (if expanded)
          if (_isExpanded && metrics.screenLoadTimes.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 8),
            const Text(
              'Slow Screens:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            ..._buildSlowScreens(metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlowScreens(PerformanceMetrics metrics) {
    final sortedScreens = metrics.screenLoadTimes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScreens.take(3).map((entry) {
      final isSlow = entry.value.inMilliseconds > 500;
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: TextStyle(
                  color: isSlow ? Colors.orange : Colors.white60,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${entry.value.inMilliseconds}ms',
              style: TextStyle(
                color: isSlow ? Colors.orange : Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Performance overlay entry point to add to MaterialApp
class PerformanceOverlayEntry extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlayEntry({
    super.key,
    required this.child,
    this.showOverlay = kDebugMode,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showOverlay) const PerformanceOverlay(),
      ],
    );
  }
}
