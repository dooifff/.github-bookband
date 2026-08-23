import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/studio_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'services/performance_service.dart';
import 'widgets/performance_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance monitoring
  PerformanceService.instance.initialize();
  
  // Initialize Firebase for FCM
  // await Firebase.initializeApp();
  
  // Initialize background message handler
  initializeBackgroundHandler();
  
  // Mark app as loaded after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerformanceService.instance.markAppLoaded();
  });
  
  runApp(const StudioBookApp());
}

class StudioBookApp extends StatelessWidget {
  const StudioBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudioProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: PerformanceOverlayEntry(
          showOverlay: true,
          child: const SplashScreen(),
        ),
      ),
    );
  }
}
