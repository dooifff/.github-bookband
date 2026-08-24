import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/booking_card.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final apiService = ApiService();
      final response = await apiService.get(ApiConstants.bookings);
      if (response['success'] == true) {
        final allBookings = List<Map<String, dynamic>>.from(response['data'] ?? []);
        final now = DateTime.now();
        setState(() {
          _upcomingBookings = allBookings.where((b) {
            final date = DateTime.tryParse(b['date'] ?? '');
            return date != null && date.isAfter(now) && (b['status'] == 'pending' || b['status'] == 'confirmed' || b['status'] == 'paid');
          }).toList();
          _pastBookings = allBookings.where((b) {
            final date = DateTime.tryParse(b['date'] ?? '');
            return date != null && date.isBefore(now) || b['status'] == 'completed' || b['status'] == 'cancelled';
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load bookings');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('Booking Saya'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorWeight: 2,
          tabs: [
            Tab(text: 'Mendatang (${_upcomingBookings.length})'),
            Tab(text: 'Riwayat (${_pastBookings.length})'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadBookings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(_upcomingBookings, true),
                    _buildBookingsList(_pastBookings, false),
                  ],
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
          const Text('Terjadi kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadBookings, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, bool isUpcoming) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.calendar_today : Icons.history, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'Tidak ada booking mendatang' : 'Belum ada riwayat booking',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              isUpcoming ? 'Booking akan muncul di sini' : 'Riwayat booking akan muncul di sini',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppTheme.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BookingCard(
              bookingCode: booking['booking_code'] ?? '',
              customerName: booking['customer_name'] ?? '',
              studioName: booking['studio_name'] ?? '',
              roomName: booking['room_name'] ?? '',
              date: booking['date'] ?? '',
              startTime: booking['start_time'] ?? '',
              endTime: booking['end_time'] ?? '',
              status: booking['status'] ?? '',
              totalPrice: booking['total'] ?? 0,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Booking detail: ${booking['booking_code']}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
