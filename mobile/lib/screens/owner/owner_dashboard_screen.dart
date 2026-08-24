import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/booking_card.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _todayBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      // Fetch owner dashboard stats
      final dashboardResponse = await apiService.get(ApiConstants.ownerDashboard);
      
      if (dashboardResponse['success'] == true) {
        final data = dashboardResponse['data'];
        
        setState(() {
          _stats = {
            'total_studios': data['total_studios'] ?? 0,
            'active_studios': data['active_studios'] ?? 0,
            'pending_bookings': data['pending_bookings'] ?? 0,
            'confirmed_bookings': data['confirmed_bookings'] ?? 0,
            'completed_bookings': data['completed_bookings'] ?? 0,
            'cancelled_bookings': data['cancelled_bookings'] ?? 0,
            'total_revenue': data['total_revenue'] ?? 0,
            'monthly_revenue': data['monthly_revenue'] ?? 0,
            'occupancy_rate': data['occupancy_rate'] ?? 0.0,
            'average_rating': data['average_rating'] ?? 0.0,
          };

          // Parse today's bookings from API response
          final bookingsData = data['today_bookings'] ?? [];
          _todayBookings = List<Map<String, dynamic>>.from(bookingsData.map((booking) => {
            'id': booking['id'],
            'booking_code': booking['booking_code'] ?? '',
            'customer_name': booking['customer_name'] ?? 'Unknown',
            'studio_name': booking['studio_name'] ?? '',
            'room_name': booking['room_name'] ?? '',
            'date': booking['date'] ?? DateTime.now().toIso8601String().split('T')[0],
            'start_time': booking['start_time'] ?? '',
            'end_time': booking['end_time'] ?? '',
            'status': booking['status'] ?? 'pending',
            'total_price': booking['total_price'] ?? 0,
          }));

          _isLoading = false;
        });
      } else {
        throw Exception(dashboardResponse['message'] ?? 'Failed to load dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 20),
                        _buildQuickStats(),
                        const SizedBox(height: 20),
                        _buildTodayBookings(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboard,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),        decoration: AppTheme.cardDecoration,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Berikut ringkasan studio Anda hari ini',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat(
                '${_stats['pending_bookings'] ?? 0}',
                'Pending',
                Icons.pending_actions,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                '${_stats['confirmed_bookings'] ?? 0}',
                'Confirmed',
                Icons.check_circle,
              ),
              const SizedBox(width: 16),
              _buildMiniStat(
                '${_stats['total_studios'] ?? 0}',
                'Studios',
                Icons.store,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLighter,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accent, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Pendapatan',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_stats['total_revenue'] ?? 0),
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pendapatan Bulan Ini',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_stats['monthly_revenue'] ?? 0),
                Icons.trending_up,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tingkat Okupansi',
                '${(_stats['occupancy_rate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.pie_chart,
                AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rating Rata-rata',
                '${(_stats['average_rating'] ?? 0.0).toStringAsFixed(1)}',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
        boxShadow: [
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Booking Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to bookings page
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todayBookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada booking hari ini',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_todayBookings.map((booking) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BookingCard(
                  bookingCode: booking['booking_code'],
                  customerName: booking['customer_name'],
                  studioName: booking['studio_name'],
                  roomName: booking['room_name'],
                  date: booking['date'],
                  startTime: booking['start_time'],
                  endTime: booking['end_time'],
                  status: booking['status'],
                  totalPrice: booking['total_price'],
                  onTap: () {
                    // Navigate to booking detail
                  },
                ),
              ))),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Kelola Studio',
                Icons.store,
                () {
                  // Navigate to studios page
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Lihat Analitik',
                Icons.analytics,
                () {
                  // Navigate to analytics page
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Laporan Pendapatan',
                Icons.receipt_long,
                () {
                  // Navigate to revenue page
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Pengaturan',
                Icons.settings,
                () {
                  // Navigate to settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Icon(icon, size: 32, color: AppTheme.accent),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
