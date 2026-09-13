import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'bulk_schedule_screen.dart';
import '../admin/admin_widgets.dart' show parseNum;

/// Bungkus halaman owner dengan AppBar + akses menu navigasi.
class OwnerScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool refreshable;
  final VoidCallback? onRefresh;
  final List<Widget>? actions;

  const OwnerScaffold({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.child,
    this.refreshable = false,
    this.onRefresh,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17)),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (refreshable)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Muat ulang',
              onPressed: onRefresh,
            ),
          ...?actions,
          IconButton(
            icon: const Icon(Icons.menu, size: 20),
            tooltip: 'Menu Owner',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppTheme.surfaceLight,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const OwnerMenuSheet(),
            ),
          ),
        ],
      ),
      body: child,
    );
  }
}

/// Daftar menu owner sebagai bottom sheet (mirip sidebar web owner).
class OwnerMenuSheet extends StatelessWidget {
  const OwnerMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'MENU OWNER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            _item(
              context,
              currentPath: currentPath,
              route: '/owner',
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),
            _item(
              context,
              currentPath: currentPath,
              route: '/owner/bookings',
              icon: Icons.event_note_outlined,
              label: 'Bookings',
            ),
            _item(
              context,
              currentPath: currentPath,
              route: '/owner/revenue',
              icon: Icons.receipt_long_outlined,
              label: 'Pendapatan',
            ),
            ListTile(
              leading: const Icon(Icons.schedule_outlined,
                  color: AppTheme.textSecondary, size: 22),
              title: const Text(
                'Blokir Jadwal Massal',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              trailing: const Icon(Icons.chevron_right,
                  size: 18, color: AppTheme.textMuted),
              onTap: () {
                Navigator.pop(context);
                showSchedulePicker(context);
              },
            ),
            const Divider(color: AppTheme.border),
            _OwnerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String currentPath,
    required String route,
    required IconData icon,
    required String label,
  }) {
    final active = currentPath == route;
    return ListTile(
      leading: Icon(icon,
          color: active ? AppTheme.accent : AppTheme.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: active ? AppTheme.accent : AppTheme.textPrimary,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: active
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            )
          : const Icon(Icons.chevron_right,
              size: 18, color: AppTheme.textMuted),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}

class _OwnerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? '';
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.accent.withOpacity(0.15),
        child: Text(
          (name.isNotEmpty ? name[0] : 'A').toUpperCase(),
          style: const TextStyle(
            color: AppTheme.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name.isEmpty ? 'User' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        (user?.role ?? 'owner').toUpperCase(),
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
        tooltip: 'Keluar',
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          await auth.logout();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }
}

/// Kartu statistik besar ala dashboard web.
class OwnerStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;

  const OwnerStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lencana status kecil berwarna (status booking).
class OwnerBadge extends StatelessWidget {
  final String text;
  final Color color;

  const OwnerBadge(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Avatar inisial pengguna.
class OwnerAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color color;

  const OwnerAvatar({
    super.key,
    required this.name,
    this.radius = 16,
    this.color = AppTheme.accent,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

/// Ubah "HH:MM:SS" menjadi "HH.MM" (format waktu aplikasi).
String formatClock(dynamic value) {
  final s = value?.toString() ?? '';
  if (s.length < 5) return s;
  return '${s.substring(0, 2)}.${s.substring(3, 5)}';
}

/// Tampilkan pesan singkat (snackbar).
void ownerSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Alur memilih studio → ruangan, lalu membuka layar Blokir Jadwal Massal.
Future<void> showSchedulePicker(BuildContext context) async {
  try {
    final apiService = ApiService();
    final response = await apiService.get(
      ApiConstants.ownerStudios,
      queryParameters: {'page': 1},
    );
    final items = response['data'];
    final studios = (items is List ? items : <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (!context.mounted) return;
    if (studios.isEmpty) {
      ownerSnack(context, 'Anda belum memiliki studio.', AppTheme.warning);
      return;
    }

    final studio = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'PILIH STUDIO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ...studios.map((s) => ListTile(
                  leading: const Icon(Icons.storefront_outlined,
                      color: AppTheme.textSecondary),
                  title: Text(
                    '${s['name']}',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    '${s['city'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                  onTap: () => Navigator.pop(sheetContext, s),
                )),
          ],
        ),
      ),
    );

    if (studio == null || !context.mounted) return;

    final roomResponse = await apiService.get(
      ApiConstants.ownerStudioRooms(parseNum(studio['id']).toInt()),
    );
    final roomData = roomResponse['data'];
    final roomsRaw = roomData is Map ? roomData['data'] : roomData;
    final rooms = (roomsRaw is List ? roomsRaw : <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (!context.mounted) return;
    if (rooms.isEmpty) {
      ownerSnack(context, 'Studio belum memiliki ruangan.', AppTheme.warning);
      return;
    }

    final room = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'PILIH RUANGAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ...rooms.map((r) => ListTile(
                  leading: const Icon(Icons.meeting_room_outlined,
                      color: AppTheme.textSecondary),
                  title: Text(
                    '${r['name']}',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Rp ${NumberFormat.decimalPattern('id').format(parseNum(r['price_per_hour']).toInt())} /jam',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                  onTap: () => Navigator.pop(sheetContext, r),
                )),
          ],
        ),
      ),
    );

    if (room == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BulkScheduleScreen(
          studioId: parseNum(studio['id']).toInt(),
          roomId: parseNum(room['id']).toInt(),
          roomName: '${room['name']}',
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ownerSnack(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          AppTheme.danger);
    }
  }
}