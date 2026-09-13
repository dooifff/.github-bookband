import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _period = 30;
  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  String? _error;

  static const List<(int, String)> periodOptions = [
    (7, '7 Hari'),
    (30, '30 Hari'),
    (90, '90 Hari'),
    (365, '1 Tahun'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.get(
        ApiConstants.adminDashboard,
        queryParameters: {'period': _period},
      );
      if (response['success'] == true) {
        setState(() {
          _data = Map<String, dynamic>.from(response['data'] ?? {});
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> get _summary {
    final s = _data['summary'];
    return s is Map ? Map<String, dynamic>.from(s) : {};
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard',
      subtitle:
          'Ringkasan platform\n${_data['period'] is Map ? '${(_data['period'] as Map)['days']} hari terakhir' : '${_period} hari terakhir'}',
      refreshable: true,
      onRefresh: _loadDashboard,
      actions: [_buildPeriodMenu()],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryGrid(),
                      const SizedBox(height: 16),
                      _buildBreakdowns(),
                      const SizedBox(height: 16),
                      _buildRecentActivities(),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodMenu() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.calendar_month_outlined, size: 20),
      tooltip: 'Periode',
      onSelected: (value) {
        if (value == _period) return;
        setState(() => _period = value);
        _loadDashboard();
      },
      itemBuilder: (context) => [
        for (final option in periodOptions)
          PopupMenuItem(
            value: option.$1,
            child: Row(
              children: [
                Icon(
                  option.$1 == _period
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: option.$1 == _period
                      ? AppTheme.accent
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(option.$2),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    final s = _summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Ringkasan'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            AdminStatCard(
              label: 'Total Users',
              value: '${parseNum(s['total_users']).toInt()}',
              icon: Icons.people_outline,
              color: AppTheme.info,
            ),
            AdminStatCard(
              label: 'Total Studios',
              value: '${parseNum(s['total_studios']).toInt()}',
              icon: Icons.storefront_outlined,
              color: AppTheme.accent,
            ),
            AdminStatCard(
              label: 'Total Bookings',
              value: '${parseNum(s['total_bookings']).toInt()}',
              icon: Icons.event_note_outlined,
              color: AppTheme.success,
            ),
            AdminStatCard(
              label: 'Revenue',
              value: idr(parseNum(s['total_revenue'])),
              icon: Icons.payments_outlined,
              color: AppTheme.warning,
            ),
            AdminStatCard(
              label: 'New Users',
              value: '${parseNum(s['new_users']).toInt()}',
              icon: Icons.person_add_alt,
              color: AppTheme.info,
            ),
            AdminStatCard(
              label: 'Reviews',
              value: '${parseNum(s['total_reviews']).toInt()}',
              icon: Icons.star_outline,
              color: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdowns() {
    final users = _data['users'] is Map
        ? Map<String, dynamic>.from(_data['users'])
        : {};
    final studios = _data['studios'] is Map
        ? Map<String, dynamic>.from(_data['studios'])
        : {};
    final bookings = _data['bookings'] is Map
        ? Map<String, dynamic>.from(_data['bookings'])
        : {};
    final payments = _data['payments'] is Map
        ? Map<String, dynamic>.from(_data['payments'])
        : {};
    final reviews = _data['reviews'] is Map
        ? Map<String, dynamic>.from(_data['reviews'])
        : {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Rincian'),
        const SizedBox(height: 12),
        _BuildCard(
          title: 'PENGGUNA',
          children: [
            _buildProgressRow(
              'Pelanggan',
              parseNum(users['customers']),
              parseNum(users['customers']) + parseNum(users['owners']) +
                  parseNum(users['admins']),
              AppTheme.info,
            ),
            _buildProgressRow(
              'Pemilik Studio',
              parseNum(users['owners']),
              parseNum(users['customers']) + parseNum(users['owners']) +
                  parseNum(users['admins']),
              AppTheme.success,
            ),
            _buildProgressRow(
              'Admin',
              parseNum(users['admins']),
              parseNum(users['customers']) + parseNum(users['owners']) +
                  parseNum(users['admins']),
              AppTheme.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BuildCard(
          title: 'STUDIOS',
          children: [
            _buildProgressRow(
              'Aktif',
              parseNum(studios['active']),
              parseNum(studios['active']) + parseNum(studios['inactive']) +
                  parseNum(studios['pending_verification']),
              AppTheme.success,
            ),
            _buildProgressRow(
              'Nonaktif',
              parseNum(studios['inactive']),
              parseNum(studios['active']) + parseNum(studios['inactive']) +
                  parseNum(studios['pending_verification']),
              AppTheme.danger,
            ),
            _buildProgressRow(
              'Menunggu Verifikasi',
              parseNum(studios['pending_verification']),
              parseNum(studios['active']) + parseNum(studios['inactive']) +
                  parseNum(studios['pending_verification']),
              AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BuildCard(
          title: 'BOOKING & PEMBAYARAN',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMiniCount(
                      'Menunggu', parseNum(bookings['pending']),
                      AppTheme.warning),
                ),
                Expanded(
                  child: _buildMiniCount(
                      'Selesai', parseNum(bookings['completed']),
                      AppTheme.success),
                ),
                Expanded(
                  child: _buildMiniCount(
                      'Dibatalkan', parseNum(bookings['cancelled']),
                      AppTheme.danger),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMiniCount(
                      'Pembayaran Menunggu', parseNum(payments['pending']),
                      AppTheme.info),
                ),
                Expanded(
                  child: _buildMiniCount(
                      'Pembayaran Gagal', parseNum(payments['failed']),
                      AppTheme.danger),
                ),
                Expanded(
                  child: _buildRating(
                      parseNum(reviews['average_rating']).toDouble(),
                      parseNum(reviews['total']).toInt()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, num value, num total, Color color) {
    final fraction = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Text(
                '${value.toInt()} · ${(fraction * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: AppTheme.surfaceLighter,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCount(String label, num value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '${value.toInt()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(double rating, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLighter.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 16, color: AppTheme.warning),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$total ulasan',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = _data['recent_activities'] is Map
        ? Map<String, dynamic>.from(_data['recent_activities'])
        : {};
    final bookings = activities['bookings'] is List
        ? activities['bookings'] as List
        : <dynamic>[];
    final users = activities['users'] is List
        ? activities['users'] as List
        : <dynamic>[];
    final studios = activities['studios'] is List
        ? activities['studios'] as List
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Aktivitas Terbaru'),
        const SizedBox(height: 12),

        // Booking terbaru
        _BuildCard(
          title: 'BOOKING TERBARU',
          children: bookings.isEmpty
              ? [_emptyLine('Belum ada booking')]
              : (bookings.take(5).map((b) {
                  final item = Map<String, dynamic>.from(b);
                  return _buildActivityRow(
                    icon: Icons.event_note,
                    color: bookingStatusColor('${item['status']}'),
                    title: '${item['user'] ?? '-'} · ${item['studio'] ?? '-'}',
                    subtitle: '${item['booking_code'] ?? ''}',
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          idr(parseNum(item['amount'])),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AdminBadge(
                          bookingStatusLabel('${item['status']}'),
                          bookingStatusColor('${item['status']}'),
                        ),
                      ],
                    ),
                    onTap: () => context.go('/admin/bookings'),
                  );
                }).toList()),
        ),
        const SizedBox(height: 12),

        // Pengguna terbaru
        _BuildCard(
          title: 'PENGGUNA TERBARU',
          children: users.isEmpty
              ? [_emptyLine('Belum ada pengguna')]
              : (users.take(5).map((u) {
                  final item = Map<String, dynamic>.from(u);
                  return _buildActivityRow(
                    icon: Icons.person_outline,
                    color: roleColor('${item['role']}'),
                    title: '${item['name'] ?? '-'}',
                    subtitle: '${item['email'] ?? ''}',
                    trailing: AdminBadge(
                      '${(item['role'] ?? '').replaceAll('_', ' ')}',
                      roleColor('${item['role']}'),
                    ),
                    onTap: () => context.go('/admin/users'),
                  );
                }).toList()),
        ),
        const SizedBox(height: 12),

        // Studio terbaru
        _BuildCard(
          title: 'STUDIO TERBARU',
          children: studios.isEmpty
              ? [_emptyLine('Belum ada studio')]
              : (studios.take(5).map((st) {
                  final item = Map<String, dynamic>.from(st);
                  return _buildActivityRow(
                    icon: Icons.storefront_outlined,
                    color: AppTheme.accent,
                    title: '${item['name'] ?? '-'}',
                    subtitle: 'oleh ${item['owner'] ?? '-'}',
                    trailing: item['is_verified'] == true
                        ? const AdminBadge('Terverifikasi', AppTheme.success)
                        : const AdminBadge('Belum Verified', AppTheme.warning),
                    onTap: () => context.go('/admin/studios'),
                  );
                }).toList()),
        ),
      ],
    );
  }

  Widget _emptyLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final s = _summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Aksi Cepat'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.people_outline,
                label: 'Users',
                note: '${parseNum(s['total_users']).toInt()} total',
                onTap: () => context.go('/admin/users'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.storefront_outlined,
                label: 'Studios',
                note:
                    '${parseNum((_data['studios'] is Map ? _data['studios'] : const {})['pending_verification']).toInt()} pending',
                onTap: () => context.go('/admin/studios'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.event_note_outlined,
                label: 'Bookings',
                note:
                    '${parseNum((_data['bookings'] is Map ? _data['bookings'] : const {})['pending']).toInt()} menunggu',
                onTap: () => context.go('/admin/bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.bolt_outlined,
                label: 'Performance',
                note: 'Monitoring server',
                onTap: () => context.go('/admin/performance'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.group_outlined,
                label: 'Subscribers',
                note: 'Kelola langganan',
                onTap: () => context.go('/admin/subscribers'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings_outlined,
                label: 'Settings',
                note: 'Pengaturan akun',
                onTap: () => context.go('/admin/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String note,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: AppTheme.accent),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  static Color roleColor(String role) {
    switch (role) {
      case 'super_admin':
      case 'admin':
        return AppTheme.danger;
      case 'owner':
        return AppTheme.success;
      case 'customer':
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }
}

class _BuildCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BuildCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}