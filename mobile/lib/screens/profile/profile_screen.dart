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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, user),
            
            const SizedBox(height: 16),
            
            // Menu Items
            _buildMenuSection(context, 'Akun', [
              _buildMenuItem(
                icon: Icons.person,
                title: 'Edit Profil',
                onTap: () {
                  // Navigate to settings page for profile edit
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Edit Profil')),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.lock,
                title: 'Ubah Password',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Ubah Password')),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.payment,
                title: 'Metode Pembayaran',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _PlaceholderScreen(title: 'Metode Pembayaran')),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 16),
            
            _buildMenuSection(context, 'Booking', [
              _buildMenuItem(
                icon: Icons.history,
                title: 'Riwayat Booking',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BookingsScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.favorite,
                title: 'Studio Favorit',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 16),
            
            _buildMenuSection(context, 'Bantuan', [
              _buildMenuItem(
                icon: Icons.help_center,
                title: 'Pusat Bantuan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center coming soon')),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.description,
                title: 'Syarat & Ketentuan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms & Conditions coming soon')),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.privacy_tip,
                title: 'Kebijakan Privasi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon')),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 16),
            
            _buildMenuSection(context, 'Lainnya', [
              _buildMenuItem(
                icon: Icons.info,
                title: 'Tentang Aplikasi',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'StudioBook',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.music_note, size: 48, color: Colors.orange),
                    children: [
                      const Text('Platform booking studio musik modern.'),
                    ],
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.star,
                title: 'Beri Rating',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rating feature coming soon')),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Version
            Text(
              'Studiobook v1.0.0',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              (user?.name ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          if (user?.phone != null && user!.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.phone!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRoleName(user?.role ?? 'customer'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'customer':
        return '👤 Customer';
      case 'owner':
        return '🏪 Studio Owner';
      case 'admin':
        return '👨‍💼 Admin';
      case 'super_admin':
        return '👑 Super Admin';
      default:
        return role;
    }
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: Colors.grey[400]),
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
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder screen for pages not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '$title',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
