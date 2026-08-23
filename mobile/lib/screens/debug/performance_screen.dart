import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/performance_service.dart';
import '../../utils/performance_profiler.dart';

/// Debug screen for viewing performance metrics
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  Timer? _refreshTimer;
  PerformanceMetrics? _metrics;
  Map<String, ProfileStats> _profileStats = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _metrics = PerformanceService.instance.getMetrics();
      _profileStats = PerformanceProfiler.instance.getAllStats();
    });
  }

  Color _getColor(double value, {double good = 50, double warning = 30}) {
    if (value >= good) return Colors.green;
    if (value >= warning) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              PerformanceService.instance.resetMetrics();
              PerformanceProfiler.instance.reset();
              _refreshData();
            },
          ),
        ],
      ),
      body: _metrics == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // FPS Card
                  _buildCard(
                    title: 'Frame Rate',
                    icon: Icons.speed,
                    child: _buildFPSSection(),
                  ),
                  const SizedBox(height: 16),

                  // Memory Card
                  _buildCard(
                    title: 'Memory Usage',
                    icon: Icons.memory,
                    child: _buildMemorySection(),
                  ),
                  const SizedBox(height: 16),

                  // Startup Card
                  _buildCard(
                    title: 'App Startup',
                    icon: Icons.timer,
                    child: _buildStartupSection(),
                  ),
                  const SizedBox(height: 16),

                  // Screen Loads Card
                  _buildCard(
                    title: 'Screen Load Times',
                    icon: Icons.view_carousel,
                    child: _buildScreenLoadsSection(),
                  ),
                  const SizedBox(height: 16),

                  // Profile Stats Card
                  if (_profileStats.isNotEmpty) ...[
                    _buildCard(
                      title: 'Operation Profiling',
                      icon: Icons.analytics,
                      child: _buildProfileStatsSection(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Actions
                  _buildCard(
                    title: 'Actions',
                    icon: Icons.settings,
                    child: _buildActionsSection(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFPSSection() {
    final fps = _metrics!.fps;
    final fpsColor = _getColor(fps);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current FPS'),
            Text(
              '${fps.toStringAsFixed(1)} FPS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: fpsColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fps / 60,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(fpsColor),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rating: ${PerformanceService.instance.getFPSRating()}'),
            Text(
              'Frame drops: ${_metrics!.getFrameDropPercentage().toStringAsFixed(1)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemorySection() {
    final memory = _metrics!.memoryUsageMB;
    final memoryColor = _getColor(
      200 - memory, // Invert for memory (lower is better)
      good: 100,
      warning: 50,
    );
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Memory Usage'),
            Text(
              '${memory.toStringAsFixed(1)} MB',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: memoryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: memory / 500, // Assume 500MB max
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(memoryColor),
        ),
        const SizedBox(height: 8),
        Text(
          memory < 100
              ? 'Memory usage is optimal'
              : memory < 200
                  ? 'Memory usage is moderate'
                  : 'Memory usage is high',
          style: TextStyle(color: memoryColor),
        ),
      ],
    );
  }

  Widget _buildStartupSection() {
    final startup = _metrics!.startupTime;
    final isSlow = startup.inMilliseconds > 2000;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Startup Time'),
            Text(
              '${startup.inMilliseconds} ms',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSlow ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isSlow
              ? 'Startup time is slower than expected'
              : 'Startup time is within normal range',
          style: TextStyle(color: isSlow ? Colors.orange : Colors.green),
        ),
      ],
    );
  }

  Widget _buildScreenLoadsSection() {
    final screens = _metrics!.screenLoadTimes;
    
    if (screens.isEmpty) {
      return const Text('No screen loads recorded yet');
    }

    // Sort by load time (slowest first)
    final sorted = screens.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final isSlow = entry.value.inMilliseconds > 500;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: isSlow ? Colors.orange : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSlow ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${entry.value.inMilliseconds} ms',
                  style: TextStyle(
                    color: isSlow ? Colors.orange[800] : Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileStatsSection() {
    final sorted = _profileStats.values.toList()
      ..sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

    return Column(
      children: sorted.take(10).map((stat) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${stat.callCount} calls',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg: ${stat.avgTimeMs.toStringAsFixed(1)} ms',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'P95: ${stat.p95TimeMs} ms',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            PerformanceService.instance.logSummary();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Summary logged to console')),
            );
          },
          icon: const Icon(Icons.console),
          label: const Text('Log Summary'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            PerformanceProfiler.instance.logAllStats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile stats logged to console')),
            );
          },
          icon: const Icon(Icons.analytics),
          label: const Text('Log Profiles'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final leaks = PerformanceProfiler.instance.checkForLeaks();
            if (leaks.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No potential memory leaks detected')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Potential leaks: ${leaks.join(', ')}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          icon: const Icon(Icons.bug_report),
          label: const Text('Check Leaks'),
        ),
      ],
    );
  }
}
