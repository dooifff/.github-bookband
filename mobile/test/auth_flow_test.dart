import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studiobook/core/router/app_router.dart';
import 'package:studiobook/providers/auth_provider.dart';
import 'package:studiobook/screens/auth/login_screen.dart';
import 'package:studiobook/screens/splash/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp(AuthProvider auth) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: AppRouter.createRouter(auth)),
    );
  }

  test('auth screens are reachable without signing in', () {
    expect(
      AppRouter.publicRoutes,
      containsAll([
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
      ]),
    );
  });

  testWidgets('app opens on the splash screen', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(buildApp(auth));

    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the splash timer finish so no timers stay pending at test end.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('unauthenticated users are sent to the login screen',
      (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(buildApp(auth));

    // Splash shows for a moment, then the router redirects to /login.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);
  });
}
