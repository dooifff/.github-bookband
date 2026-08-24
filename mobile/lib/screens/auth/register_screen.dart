import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Registration failed'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            right: -MediaQuery.of(context).size.width * 0.2,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.accent.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: AppTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_outlined,
                          size: 40,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join StudioBook',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find and book the best studios',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Name
                    _buildField(
                      controller: _nameController,
                      label: 'FULL NAME',
                      hint: 'Your full name',
                      icon: Icons.person_outline,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _buildField(
                      controller: _emailController,
                      label: 'EMAIL',
                      hint: 'your@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    _buildField(
                      controller: _phoneController,
                      label: 'PHONE',
                      hint: '08123456789',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildField(
                      controller: _passwordController,
                      label: 'PASSWORD',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildField(
                      controller: _confirmPasswordController,
                      label: 'CONFIRM PASSWORD',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Register button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _register,
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
                                    'Create Account',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: suffixIcon,
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
      validator: validator,
    );
  }
}
