import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          // Ambient glow orbs
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.12,
            right: -MediaQuery.of(context).size.width * 0.15,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: AppTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.25),
                              blurRadius: 24,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentHover],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'StudioBook',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Premium Music Studio Booking',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 44),

                      // Welcome text
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sign in to your account to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'EMAIL ADDRESS',
                          labelStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06,
                          ),
                          hintText: 'admin@studiobook.com',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted, size: 20),
                          filled: true,
                          fillColor: AppTheme.surfaceLight.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.danger),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'PASSWORD',
                          labelStyle: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.06,
                          ),
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceLight.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.danger),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Login button
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: AppTheme.primary,
                                disabledBackgroundColor: AppTheme.accent.withOpacity(0.4),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.01,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      Consumer<AuthProvider>(
                        builder: (context, auth, child) {
                          if (auth.error != null) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 28),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Demo accounts
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'QUICK ACCESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DemoAccountButton(
                              email: 'admin@studiobook.com',
                              role: 'Admin',
                              color: AppTheme.accent,
                              onTap: () {
                                _emailController.text = 'admin@studiobook.com';
                                _passwordController.text = 'password';
                              },
                            ),
                            const SizedBox(height: 6),
                            _DemoAccountButton(
                              email: 'owner@studiobook.com',
                              role: 'Owner',
                              color: AppTheme.success,
                              onTap: () {
                                _emailController.text = 'owner@studiobook.com';
                                _passwordController.text = 'password';
                              },
                            ),
                            const SizedBox(height: 6),
                            _DemoAccountButton(
                              email: 'customer@studiobook.com',
                              role: 'Customer',
                              color: AppTheme.info,
                              onTap: () {
                                _emailController.text = 'customer@studiobook.com';
                                _passwordController.text = 'password';
                              },
                            ),
                          ],
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

class _DemoAccountButton extends StatelessWidget {
  final String email;
  final String role;
  final Color color;
  final VoidCallback onTap;

  const _DemoAccountButton({
    required this.email,
    required this.role,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLighter.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              email,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
