import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await context.read<AuthProvider>().initialize();
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuthenticated ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Ambient glow orb — top right
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                top: -size.height * 0.15,
                right: -size.width * 0.1,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.08 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Ambient glow orb — bottom left
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -size.height * 0.1,
                left: -size.width * 0.15,
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.05 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with glow
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: AppTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.3 * _glowAnimation.value),
                              blurRadius: 30,
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 56,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentHover, AppTheme.accent],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'StudioBook',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      const Text(
                        'Premium Music Studio Booking',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 56),

                      // Loading indicator
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accent.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
