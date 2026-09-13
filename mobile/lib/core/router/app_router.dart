import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/explore/explore_screen.dart';
import '../../screens/studio/studio_detail_screen.dart';
import '../../screens/booking/booking_screen.dart';
import '../../screens/booking/pricing_preview_screen.dart';
import '../../screens/bookings/bookings_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_room_screen.dart';
import '../../screens/referral/referral_screen.dart';
import '../../screens/review/review_form_screen.dart';
import '../../screens/owner/owner_dashboard_screen.dart';
import '../../screens/owner/owner_bookings_screen.dart';
import '../../screens/owner/owner_revenue_screen.dart';
import '../../screens/owner/bulk_schedule_screen.dart';
import '../../screens/debug/performance_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_studios_screen.dart';
import '../../screens/admin/admin_subscribers_screen.dart';
import '../../screens/admin/admin_bookings_screen.dart';
import '../../screens/admin/admin_performance_screen.dart';
import '../../screens/admin/admin_alerts_screen.dart';
import '../../screens/admin/admin_comparison_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/admin/admin_schedule_settings_screen.dart';

/// Route helpers for screens that need more than a path parameter.
///
/// Screens that carry an in-memory object (booking confirmation, payment and
/// booking success) are pushed with `Navigator` from the flow that owns the
/// data, so they intentionally have no deep link here.
class AppRouter {
  /// Routes that can be opened without being signed in.
  static const Set<String> publicRoutes = {
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  };

  /// Builds the router for the given [auth] state.
  ///
  /// The router listens to [auth], so signing in/out re-evaluates the redirect
  /// and unauthenticated users always land on the login screen.
  static GoRouter createRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;

        // The splash screen decides on its own where to go next.
        if (location == '/splash') return null;

        final isPublic = publicRoutes.contains(location);

        if (!auth.isAuthenticated) {
          return isPublic ? null : '/login';
        }

        // Already signed in: keep the user out of the auth screens.
        if (location == '/login' || location == '/register') {
          return switch (auth.user?.role) {
            'owner' => '/owner',
            'admin' || 'super_admin' => '/admin',
            _ => '/',
          };
        }

        return null;
      },
      routes: _routes,
    );
  }

  static final List<RouteBase> _routes = [
      // Splash / entry point
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return ResetPasswordScreen(
            token: params['token'] ?? '',
            email: params['email'] ?? '',
          );
        },
      ),

      // Home with bottom nav
      ShellRoute(
        builder: (context, state, child) => _ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const _HomeTab(),
            routes: [
              GoRoute(
                path: 'explore',
                name: 'explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Studio detail (full-screen, no bottom nav)
      GoRoute(
        path: '/studio/:slug',
        name: 'studioDetail',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return StudioDetailScreen(studioSlug: slug);
        },
      ),

      // Booking flow
      GoRoute(
        path: '/book/:studioSlug',
        name: 'booking',
        builder: (context, state) {
          final slug = state.pathParameters['studioSlug']!;
          return BookingScreen(studioSlug: slug);
        },
      ),
      GoRoute(
        path: '/pricing/preview',
        name: 'pricingPreview',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return PricingPreviewScreen(
            roomId: int.tryParse(params['roomId'] ?? '') ?? 0,
            roomName: params['roomName'] ?? 'Room',
          );
        },
      ),

      // Chat
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        name: 'chatRoom',
        builder: (context, state) {
          final roomId = int.tryParse(state.pathParameters['roomId'] ?? '') ?? 0;
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : const <String, dynamic>{};
          return ChatRoomScreen(
            roomId: roomId,
            otherUser: extra['otherUser'] as Map<String, dynamic>?,
            studioName: extra['studioName'] as String?,
          );
        },
      ),

      // Referral
      GoRoute(
        path: '/referral',
        name: 'referral',
        builder: (context, state) => const ReferralScreen(),
      ),

      // Review
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return ReviewFormScreen(
            studioId: int.tryParse(params['studioId'] ?? '') ?? 0,
            bookingId: int.tryParse(params['bookingId'] ?? ''),
          );
        },
      ),

      // Owner routes
      GoRoute(
        path: '/owner',
        name: 'owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/owner/bookings',
        name: 'ownerBookings',
        builder: (context, state) => const OwnerBookingsScreen(),
      ),
      GoRoute(
        path: '/owner/revenue',
        name: 'ownerRevenue',
        builder: (context, state) => const OwnerRevenueScreen(),
      ),
      GoRoute(
        path: '/owner/schedule',
        name: 'ownerSchedule',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return BulkScheduleScreen(
            studioId: int.tryParse(params['studioId'] ?? '') ?? 0,
            roomId: int.tryParse(params['roomId'] ?? '') ?? 0,
            roomName: params['roomName'] ?? 'Room',
          );
        },
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'adminUsers',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/studios',
        name: 'adminStudios',
        builder: (context, state) => const AdminStudiosScreen(),
      ),
      GoRoute(
        path: '/admin/subscribers',
        name: 'adminSubscribers',
        builder: (context, state) => const AdminSubscribersScreen(),
      ),
      GoRoute(
        path: '/admin/bookings',
        name: 'adminBookings',
        builder: (context, state) => const AdminBookingsScreen(),
      ),
      GoRoute(
        path: '/admin/performance',
        name: 'adminPerformance',
        builder: (context, state) => const AdminPerformanceScreen(),
      ),
      GoRoute(
        path: '/admin/alerts',
        name: 'adminAlerts',
        builder: (context, state) => const AdminAlertsScreen(),
      ),
      GoRoute(
        path: '/admin/comparison',
        name: 'adminComparison',
        builder: (context, state) => const AdminComparisonScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'adminSettings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/settings/schedule',
        name: 'adminScheduleSettings',
        builder: (context, state) => const AdminScheduleSettingsScreen(),
      ),

      // Debug
      GoRoute(
        path: '/debug/performance',
        name: 'debugPerformance',
        builder: (context, state) => const PerformanceScreen(),
      ),
  ];
}

/// Shell for bottom navigation bar
class _ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithNavBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Home tab placeholder - delegates to actual HomeScreen content
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
