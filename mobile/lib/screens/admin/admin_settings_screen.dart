import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'admin_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  String? _profileError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _profileError = 'Nama dan email wajib diisi.');
      return;
    }
    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      name: name,
      email: email,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    if (ok) {
      _snack('Profil berhasil diperbarui', AppTheme.success);
    } else {
      setState(() {
        _profileError =
            auth.error?.replaceFirst('Exception: ', '') ?? 'Gagal memperbarui profil.';
      });
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'Semua kolom wajib diisi.');
      return;
    }
    if (next.length < 8) {
      setState(() => _passwordError = 'Password baru minimal 8 karakter.');
      return;
    }
    if (next != confirm) {
      setState(() => _passwordError = 'Konfirmasi password tidak cocok.');
      return;
    }
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.updatePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _snack('Password berhasil diubah', AppTheme.success);
    } else {
      setState(() {
        _passwordError =
            auth.error?.replaceFirst('Exception: ', '') ?? 'Gagal mengubah password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return AdminScaffold(
      title: 'Pengaturan',
      subtitle: user?.name ?? '',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminSectionTitle('Profil'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    hintText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'No. HP (opsional)',
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (_profileError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _profileError!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.danger),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingProfile ? null : _saveProfile,
                    icon: _savingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.textPrimary),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Simpan Profil'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AdminSectionTitle('Ubah Password'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Password saat ini',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Password baru',
                    helperText: 'Minimal 8 karakter',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi password baru',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                ),
                if (_passwordError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _passwordError!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.danger),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _savingPassword ? null : _savePassword,
                    icon: _savingPassword
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.textPrimary),
                          )
                        : const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Ubah Password'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AdminSectionTitle('Jadwal Laporan'),
          const SizedBox(height: 10),
          AdminTapCard(
            onTap: () => context.go('/admin/settings/schedule'),
            child: const Row(
              children: [
                Icon(Icons.schedule_send_outlined, color: AppTheme.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Laporan Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Atur pengiriman laporan harian, mingguan, dan bulanan',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}