import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/studio_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/referral_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/studio_repository.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'services/performance_service.dart';
import 'widgets/performance_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase. It is optional: without platform configuration
  // (e.g. `firebase_options.dart` on web) the app still runs, it just has no
  // push notifications.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  // Initialize performance monitoring
  PerformanceService.instance.initialize();

  // Mark app as loaded after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerformanceService.instance.markAppLoaded();
  });

  runApp(StudioBookApp(firebaseReady: firebaseReady));
}

class StudioBookApp extends StatefulWidget {
  /// Whether [Firebase.initializeApp] succeeded, i.e. notifications are usable.
  final bool firebaseReady;

  const StudioBookApp({super.key, this.firebaseReady = false});

  @override
  State<StudioBookApp> createState() => _StudioBookAppState();
}

class _StudioBookAppState extends State<StudioBookApp> {
  final _notificationService = PushNotificationService();

  /// Owned here (instead of by the provider tree) so the router can listen to
  /// the auth state and redirect unauthenticated users to the login screen.
  final _authProvider = AuthProvider();
  late final _router = AppRouter.createRouter(_authProvider);

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize push notifications after first frame
    if (widget.firebaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationService.initialize(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared API client and the repositories that screens read directly.
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<AuthRepository>(create: (context) => AuthRepository(context.read<ApiService>())),
        Provider<StudioRepository>(create: (context) => StudioRepository(context.read<ApiService>())),
        Provider<BookingRepository>(create: (context) => BookingRepository(context.read<ApiService>())),
        Provider<ChatRepository>(create: (context) => ChatRepository(context.read<ApiService>())),
        Provider<ReviewRepository>(create: (context) => ReviewRepository(context.read<ApiService>())),
        Provider<ReferralRepository>(create: (context) => ReferralRepository(context.read<ApiService>())),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => StudioProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        builder: (context, child) {
          return PerformanceOverlayEntry(
            showOverlay: true,
            child: child!,
          );
        },
      ),
    );
  }
}
