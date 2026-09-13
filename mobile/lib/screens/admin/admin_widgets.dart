import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';

/// Judul seksi kecil dengan garis aksen.
class AdminSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AdminSectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Bungkus halaman admin dengan AppBar + akses menu navigasi.
class AdminScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool refreshable;
  final VoidCallback? onRefresh;
  final List<Widget>? actions;

  const AdminScaffold({
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
            tooltip: 'Menu Admin',
            onPressed: () => _showAdminMenu(context),
          ),
        ],
      ),
      body: child,
    );
  }

  void _showAdminMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AdminMenuSheet(),
    );
  }
}

/// Daftar menu admin (meniru sidebar website) sebagai bottom sheet.
class AdminMenuSheet extends StatelessWidget {
  const AdminMenuSheet({super.key});

  static const items = [
    (route: '/admin', icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (route: '/admin/users', icon: Icons.people_outline, label: 'Users'),
    (route: '/admin/studios', icon: Icons.storefront_outlined, label: 'Studios'),
    (route: '/admin/subscribers', icon: Icons.group_outlined, label: 'Subscribers'),
    (route: '/admin/bookings', icon: Icons.event_note_outlined, label: 'Bookings'),
    (route: '/admin/performance', icon: Icons.bolt_outlined, label: 'Performance'),
    (route: '/admin/alerts', icon: Icons.notifications_active_outlined, label: 'Alerts'),
    (route: '/admin/comparison', icon: Icons.insights_outlined, label: 'Comparison'),
    (route: '/admin/settings', icon: Icons.settings_outlined, label: 'Settings'),
    (route: '/admin/settings/schedule', icon: Icons.schedule_outlined, label: 'Jadwal Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdminMenu = ModalRoute.of(context)?.isCurrent ?? true;
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
                'MENU ADMIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ...items.map((item) {
              final currentPath =
                  GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
              final active = currentPath == item.route ||
                  (item.route != '/admin' &&
                      currentPath.startsWith(item.route));
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: active ? AppTheme.accent : AppTheme.textSecondary,
                  size: 22,
                ),
                title: Text(
                  item.label,
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
                  context.go(item.route);
                },
              );
            }),
            const Divider(color: AppTheme.border),
            _UserFooter(isAdminMenu: isAdminMenu),
          ],
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  final bool isAdminMenu;

  const _UserFooter({required this.isAdminMenu});

  void _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (isAdminMenu) Navigator.pop(context);
    await auth.logout();
    if (context.mounted) context.go('/login');
  }

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
        user?.name ?? 'User',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        (user?.role ?? 'customer').replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
        tooltip: 'Keluar',
        onPressed: () => _logout(context),
      ),
    );
  }
}

/// Kartu statistik ringkas.
class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;

  const AdminStatCard({
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
            children: [
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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

/// Lencana status berwarna.
class AdminBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AdminBadge(this.text, this.color, {super.key});

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

/// Kartu klik yang menampilkan baris data.
class AdminTapCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const AdminTapCard({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.cardDecoration,
          child: child,
        ),
      ),
    );
  }
}

/// Baris label/nilai biasa untuk halaman detail.
class AdminDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AdminDetailRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(
              'Terjadi kesalahan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String message;

  const AdminEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilah pencarian & filter umum untuk halaman daftar admin.
class AdminFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onFilterChanged;
  final String? filterValue;
  final List<(String, String)> filterOptions;
  final String filterLabel;

  const AdminFilterBar({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.onFilterChanged,
    required this.filterValue,
    required this.filterOptions,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (v) => onSearch(v),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari...',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in filterOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        option.$2,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      selected: filterValue == option.$1,
                      onSelected: (_) => onFilterChanged(option.$1),
                      selectedColor: AppTheme.accent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: filterValue == option.$1
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        fontWeight: filterValue == option.$1
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pemformat & pembantu status (sesuai website)
// ─────────────────────────────────────────────

num parseNum(dynamic value, [num fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value;
  final n = num.tryParse(value.toString().replaceAll(',', '.'));
  return n ?? fallback;
}

DateTime? parseDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  try {
    return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
  } catch (_) {
    return null;
  }
}

String formatDate(dynamic value, {bool long = true}) {
  final d = parseDate(value);
  if (d == null) return '-';
  return Formatters.date(d, format: long ? 'long' : 'short');
}

String bookingStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu';
    case 'awaiting_payment':
      return 'Menunggu Pembayaran';
    case 'confirmed':
      return 'Dikonfirmasi';
    case 'paid':
      return 'Dibayar';
    case 'ongoing':
      return 'Berlangsung';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status.replaceAll('_', ' ');
  }
}

Color bookingStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.warning;
    case 'awaiting_payment':
      return AppTheme.info;
    case 'confirmed':
      return AppTheme.success;
    case 'paid':
      return AppTheme.info;
    case 'ongoing':
      return AppTheme.accent;
    case 'completed':
      return AppTheme.success;
    case 'cancelled':
      return AppTheme.danger;
    default:
      return AppTheme.textMuted;
  }
}

String subscriptionStatusLabel(String status) {
  switch (status) {
    case 'active':
      return 'Aktif';
    case 'expired':
      return 'Expired';
    case 'removed':
      return 'Dihapus';
    default:
      return 'Tidak Aktif';
  }
}

Color subscriptionStatusColor(String status) {
  switch (status) {
    case 'active':
      return AppTheme.success;
    case 'expired':
    case 'removed':
      return AppTheme.danger;
    default:
      return AppTheme.textMuted;
  }
}

Color ratingColor(double rating) {
  if (rating >= 4.5) return AppTheme.success;
  if (rating >= 3.5) return AppTheme.warning;
  return AppTheme.danger;
}

/// Hari tersisa menuju [expiresAt] — dipakai kartu subscriber.
String daysLeftText(dynamic expiresAt) {
  final d = parseDate(expiresAt);
  if (d == null) return '-';
  final days = d.difference(DateTime.now()).inDays;
  if (days < 0) return '${days.abs()} hari lalu';
  return 'Sisa $days hari';
}

Color daysLeftColor(dynamic expiresAt) {
  final d = parseDate(expiresAt);
  if (d == null) return AppTheme.textMuted;
  final days = d.difference(DateTime.now()).inDays;
  if (days < 0) return AppTheme.danger;
  if (days <= 7) return AppTheme.warning;
  if (days <= 30) return const Color(0xFFFACC15);
  return AppTheme.success;
}

String idr(num amount) {
  return NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)
      .format(amount);
}

String percent(num value) => '${(value).toStringAsFixed(1)}%';