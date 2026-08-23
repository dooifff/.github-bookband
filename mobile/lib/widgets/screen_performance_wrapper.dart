import 'package:flutter/material.dart';
import '../services/performance_service.dart';

/// A wrapper widget that automatically tracks screen load performance
class ScreenPerformanceWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final bool enableTracking;

  const ScreenPerformanceWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.enableTracking = true,
  });

  @override
  State<ScreenPerformanceWrapper> createState() => _ScreenPerformanceWrapperState();
}

class _ScreenPerformanceWrapperState extends State<ScreenPerformanceWrapper>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (widget.enableTracking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceService.instance.startScreenLoad(widget.screenName);
      });
    }
  }

  @override
  void dispose() {
    if (widget.enableTracking) {
      PerformanceService.instance.stopScreenLoad(widget.screenName);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track app lifecycle for more accurate timing
    if (state == AppLifecycleState.resumed && widget.enableTracking) {
      PerformanceService.instance.startScreenLoad('${widget.screenName}_resume');
    } else if (state == AppLifecycleState.paused && widget.enableTracking) {
      PerformanceService.instance.stopScreenLoad('${widget.screenName}_resume');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily wrap any widget with performance tracking
extension PerformanceTrackingExtension on Widget {
  Widget withPerformanceTracking(String screenName) {
    return ScreenPerformanceWrapper(
      screenName: screenName,
      child: this,
    );
  }
}
