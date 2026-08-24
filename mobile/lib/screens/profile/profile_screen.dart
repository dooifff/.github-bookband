import 'package:flutter/material.dart';
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
              _buildMenuItem(context, icon: Icons.person_outline, title: 'Edit Profil', onTap: () {}),
              _buildMenuItem(context, icon: Icons.lock_outline, title: 'Ubah Password', onTap: () {}),
              _buildMenuItem(context, icon: Icons.payment_outlined, title: 'Metode Pembayaran', onTap: () {}, isLast: true),
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
              _buildMenuItem(context, icon: Icons.help_outline, title: 'Pusat Bantuan', onTap: () {}),
              _buildMenuItem(context, icon: Icons.description_outlined, title: 'Syarat & Ketentuan', onTap: () {}),
              _buildMenuItem(context, icon: Icons.privacy_tip_outlined, title: 'Kebijakan Privasi', onTap: () {}, isLast: true),
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
              _buildMenuItem(context, icon: Icons.star_outline, title: 'Beri Rating', onTap: () {}, isLast: true),
            ]),
            const SizedBox(height: 24),

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
}
