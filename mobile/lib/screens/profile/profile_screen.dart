import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../favorites/favorites_screen.dart';
import '../bookings/bookings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, user),
            const SizedBox(height: 20),

            // Menu Items
            _buildMenuSection(context, 'AKUN', [
              _buildMenuItem(context, icon: Icons.person_outline, title: 'Edit Profil', onTap: () {
                _openEditProfile(context, authProvider);
              }),
              _buildMenuItem(context, icon: Icons.lock_outline, title: 'Ubah Password', onTap: () {
                _openChangePassword(context, authProvider);
              }),
              _buildMenuItem(context, icon: Icons.payment_outlined, title: 'Metode Pembayaran', onTap: () {
                _showPaymentMethods(context);
              }, isLast: true),
            ]),
            const SizedBox(height: 16),

            _buildMenuSection(context, 'BOOKING', [
              _buildMenuItem(context, icon: Icons.history_outlined, title: 'Riwayat Booking', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookingsScreen()));
              }),
              _buildMenuItem(context, icon: Icons.favorite_outline, title: 'Studio Favorit', onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
              }, isLast: true),
            ]),
            const SizedBox(height: 16),

            _buildMenuSection(context, 'BANTUAN', [
              _buildMenuItem(context, icon: Icons.help_outline, title: 'Pusat Bantuan', onTap: () {
                _showHelp(context);
              }),
              _buildMenuItem(context, icon: Icons.description_outlined, title: 'Syarat & Ketentuan', onTap: () {
                _showLegal(context, title: 'Syarat & Ketentuan', body: _termsText());
              }),
              _buildMenuItem(context, icon: Icons.privacy_tip_outlined, title: 'Kebijakan Privasi', onTap: () {
                _showLegal(context, title: 'Kebijakan Privasi', body: _privacyText());
              }, isLast: true),
            ]),
            const SizedBox(height: 16),

            _buildMenuSection(context, 'LAINNYA', [
              _buildMenuItem(context, icon: Icons.info_outline, title: 'Tentang Aplikasi', onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'StudioBook',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.music_note, size: 32, color: AppTheme.primary),
                  ),
                  children: [const Text('Platform booking studio musik premium.')],
                );
              }),
              _buildMenuItem(context, icon: Icons.star_outline, title: 'Beri Rating', onTap: () {
                _showLegal(context,
                    title: 'Beri Rating',
                    body: 'Terima kasih telah menggunakan StudioBook!\n\n'
                        'Rating Anda di store membantu kami terus berkembang. '
                        'Silakan beri rating dan ulasan melalui Google Play Store atau App Store.');
              }, isLast: true),
            ]),
            const SizedBox(height: 16),

            if (user?.isAdmin == true) ...[
              _buildMenuSection(context, 'ADMIN', [
                _buildMenuItem(context, icon: Icons.admin_panel_settings_outlined, title: 'Admin Panel', onTap: () {
                  context.go('/admin');
                }, isLast: true),
              ]),
              const SizedBox(height: 16),
            ],

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
                  label: const Text('Keluar', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.danger, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('StudioBook v1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                (user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (user?.phone != null && user!.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(user.phone!, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Text(
              _getRoleName(user?.role ?? 'customer'),
              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'customer': return '👤 Customer';
      case 'owner': return '🏪 Studio Owner';
      case 'admin': return '👨‍💼 Admin';
      case 'super_admin': return '👑 Super Admin';
      default: return role;
    }
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.08),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: isLast ? null : const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () { Navigator.pop(context); context.read<AuthProvider>().logout(); },
            child: const Text('Keluar', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  void _openEditProfile(BuildContext context, AuthProvider authProvider) {
    final nameCtrl = TextEditingController(text: authProvider.user?.name ?? '');
    final emailCtrl = TextEditingController(text: authProvider.user?.email ?? '');
    final phoneCtrl = TextEditingController(text: authProvider.user?.phone ?? '');
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final ok = await authProvider.updateProfile(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (!dialogContext.mounted) return;
                      if (ok) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil berhasil diperbarui'),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.error ?? 'Gagal memperbarui profil'),
                            backgroundColor: AppTheme.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChangePassword(BuildContext context, AuthProvider authProvider) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ubah Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password saat ini'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password baru'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ulangi password baru'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (newCtrl.text.isEmpty || newCtrl.text.length < 8) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Password baru minimal 8 karakter'),
                            backgroundColor: AppTheme.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Konfirmasi password tidak cocok'),
                            backgroundColor: AppTheme.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      final ok = await authProvider.updatePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (ok) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password berhasil diubah'),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.error ?? 'Gagal mengubah password'),
                            backgroundColor: AppTheme.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metode Pembayaran'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentMethodRow(label: 'Transfer Bank (BCA, BNI, Mandiri)', icon: Icons.account_balance),
            SizedBox(height: 10),
            _PaymentMethodRow(label: 'QRIS', icon: Icons.qr_code_2),
            SizedBox(height: 10),
            _PaymentMethodRow(label: 'E-Wallet (GoPay, OVO, DANA)', icon: Icons.wallet),
            SizedBox(height: 10),
            _PaymentMethodRow(label: 'Kartu Kredit / Debit', icon: Icons.credit_card),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pusat Bantuan'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Cara melakukan booking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              SizedBox(height: 4),
              Text('Pilih studio, cek ketersediaan waktu, dan selesaikan pembayaran.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              SizedBox(height: 12),
              Text('• Pembatalan & refund',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              SizedBox(height: 4),
              Text('Pembatalan dapat dilakukan melalui halaman booking sebelum jadwal dimulai.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              SizedBox(height: 12),
              Text('• Kendala teknis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              SizedBox(height: 4),
              Text('Hubungi tim dukungan melalui email support@studiobook.com.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showLegal(BuildContext context, {required String title, required String body}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _termsText() {
    return '1. Layanan ini digunakan untuk booking studio musik premium.\n\n'
        '2. Pengguna wajib melakukan pembayaran sesuai tarif yang ditampilkan.\n\n'
        '3. Pembatalan maksimal H-1 sebelum jadwal untuk mendapatkan refund sesuai kebijakan.\n\n'
        '4. Dilarang menyalahgunakan platform untuk aktivitas yang melanggar hukum.\n\n'
        '5. StudioBook berhak menonaktifkan akun yang terbukti melanggar ketentuan.';
  }

  String _privacyText() {
    return '1. Data pribadi Anda digunakan untuk keperluan layanan booking dan komunikasi.\n\n'
        '2. Kami tidak membagikan data pribadi kepada pihak ketiga tanpa izin, kecuali diwajibkan hukum.\n\n'
        '3. Data pembayaran diproses oleh penyedia payment gateway terpercaya.\n\n'
        '4. Anda dapat meminta penghapusan akun melalui dukungan pelanggan.';
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PaymentMethodRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}
