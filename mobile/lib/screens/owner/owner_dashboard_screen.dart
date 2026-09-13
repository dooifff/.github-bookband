import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../admin/admin_widgets.dart'
    show parseNum, formatDate, bookingStatusLabel, bookingStatusColor, idr;
import 'owner_widgets.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final ApiService _api = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await _api.get(ApiConstants.ownerDashboard);
    return Map<String, dynamic>.from(response['data'] ?? const {});
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OwnerScaffold(
      title: 'Owner Dashboard',
      subtitle: 'Ringkasan usaha kamu',
      refreshable: true,
      onRefresh: _reload,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          return _DashboardBody(data: snapshot.data ?? const {});
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: AppTheme.danger),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat dashboard',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final summary = Map<String, dynamic>.from(data['summary'] ?? const {});
    final bookings = Map<String, dynamic>.from(data['bookings'] ?? const {});
    final todayBookings = _toList(data['today_bookings']);
    final upcomingBookings = _toList(data['upcoming_bookings']);
    final recentReviews = _toList(data['recent_reviews']);

    return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _WelcomeCard(todayBookings: todayBookings.length),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OwnerStatCard(
                  label: 'STUDIO SAYA',
                  value: '${parseNum(summary['total_studios']).toInt()}',
                  icon: Icons.storefront_outlined,
                  color: AppTheme.accent,
                  note: 'Studio aktif',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OwnerStatCard(
                  label: 'TOTAL BOOKING',
                  value: '${parseNum(summary['total_bookings']).toInt()}',
                  icon: Icons.event_available_outlined,
                  color: AppTheme.info,
                  note: 'Semua pemesanan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OwnerStatCard(
                  label: 'MENUNGGU',
                  value:
                      '${parseNum(bookings['pending']).toInt()}',
                  icon: Icons.hourglass_top,
                  color: AppTheme.warning,
                  note: 'Perlu ditindaklanjuti',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OwnerStatCard(
                  label: 'PENDAPATAN',
                  value: idr(parseNum(summary['total_revenue'])),
                  icon: Icons.payments_outlined,
                  color: AppTheme.success,
                  note: 'Total revenue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _QuickActions(),
          const SizedBox(height: 6),
          if (todayBookings.isNotEmpty) ...[
            _SectionHeader(
              title: 'PEMESANAN HARI INI',
              count: '${todayBookings.length}',
              onSeeAll: () => context.go('/owner/bookings'),
            ),
            const SizedBox(height: 8),
            ...todayBookings.map((b) => _BookingRow(
                  booking: b,
                  showRoom: true,
                  showDate: false,
                  onTap: () => context.go('/owner/bookings'),
                )),
          ],
          const SizedBox(height: 16),
          if (upcomingBookings.isNotEmpty) ...[
            _SectionHeader(
              title: 'PEMESANAN MENDATANG',
              count: '${upcomingBookings.length}',
              onSeeAll: () => context.go('/owner/bookings'),
            ),
            const SizedBox(height: 8),
            ...upcomingBookings.map((b) => _BookingRow(
                  booking: b,
                  showRoom: true,
                  showDate: true,
                  onTap: () => context.go('/owner/bookings'),
                )),
          ],
          if (recentReviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(title: 'ULASAN TERBARU'),
            const SizedBox(height: 8),
            _ReviewCard(review: recentReviews.first),
            const SizedBox(height: 8),
            ...recentReviews.skip(1).map((r) => _ReviewCard(review: r)),
          ],
          if (todayBookings.isEmpty &&
              upcomingBookings.isEmpty &&
              recentReviews.isEmpty) ...[
            const SizedBox(height: 24),
            const _EmptyState(),
          ],
        ],
    );
  }

  static List<Map<String, dynamic>> _toList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }
}

class _WelcomeCard extends StatelessWidget {
  final int todayBookings;

  const _WelcomeCard({required this.todayBookings});

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().user?.name ?? 'Owner';
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accent, Color(0xFF6A5AE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name 👋',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$todayBookings',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const Text(
                'hari ini',
                style: TextStyle(fontSize: 11, color: AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AKSI CEPAT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.event_note_outlined,
                label: 'Kelola\nBooking',
                color: AppTheme.accent,
                onTap: () => context.go('/owner/bookings'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'Lihat\nPendapatan',
                color: AppTheme.success,
                onTap: () => context.go('/owner/revenue'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.schedule_outlined,
                label: 'Blokir\nJadwal',
                color: AppTheme.warning,
                onTap: () => showSchedulePicker(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.count, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        if (count != null)
          Text(
            count!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingRow extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool showRoom;
  final bool showDate;
  final VoidCallback onTap;

  const _BookingRow({
    required this.booking,
    required this.showRoom,
    required this.showDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = (booking['user'] ?? '').toString();
    final studio = (booking['studio'] ?? '').toString();
    final room = (booking['room'] ?? '').toString();
    final status = (booking['status'] ?? '').toString();
    final statusLabel = (booking['status_label'] ?? bookingStatusLabel(status));
    final statusColor = bookingStatusColor(status);
    final amount = parseNum(booking['amount']);
    final combinedTime = '${booking['time'] ?? ''}'.trim();
    final timeRange = combinedTime.isNotEmpty
        ? combinedTime
        : '${formatClock(booking['start_time'])} - ${formatClock(booking['end_time'])}';

    final String subtitle;
    if (showDate) {
      final d = formatDate(booking['date'], long: false);
      subtitle = '$d • ${showRoom ? '$room • ' : ''}$timeRange';
    } else {
      subtitle = showRoom ? '$room • $timeRange' : timeRange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            OwnerAvatar(name: user),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      OwnerBadge(statusLabel, statusColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (studio.isNotEmpty)
                    Text(
                      studio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (amount > 0)
              Text(
                idr(amount),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = (review['user'] ?? '').toString();
    final studio = (review['studio'] ?? '').toString();
    final rating = parseNum(review['rating']).toDouble();
    final comment = (review['comment'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OwnerAvatar(name: user),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (studio.isNotEmpty)
                      Text(
                        studio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating.round() ? Icons.star : Icons.star_border,
                    size: 15,
                    color: AppTheme.warning,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.isEmpty ? 'Tidak ada komentar.' : comment,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.dashboard_customize_outlined,
            size: 44, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        const Text(
          'Belum ada aktivitas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Booking dan ulasan kamu akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }
}