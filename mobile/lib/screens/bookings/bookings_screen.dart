import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/booking_repository.dart';
import '../../widgets/booking_card.dart';
import '../booking/payment_screen.dart';
import '../review/review_form_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  static const _upcomingStatuses = {
    'pending',
    'awaiting_payment',
    'paid',
    'confirmed',
    'ongoing',
  };

  late TabController _tabController;
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Deferred so the first frame finishes before we touch setState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<BookingRepository>();
      final result = await repository.getBookings();
      final bookings = (result['bookings'] as List).cast<Booking>();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      setState(() {
        _upcomingBookings = bookings.where((booking) {
          if (!_upcomingStatuses.contains(booking.status)) return false;
          final date = DateTime.tryParse(booking.date);
          // Keep bookings with an unparsable date visible while still open.
          return date == null || !date.isBefore(startOfToday);
        }).toList();
        _pastBookings =
            bookings.where((booking) => !_upcomingBookings.contains(booking)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final repository = context.read<BookingRepository>();
    try {
      await repository.cancelBooking(booking.id, reason: 'Dibatalkan oleh customer');
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking dibatalkan'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _openPayment(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          booking: booking,
          totalAmount: booking.total.toInt(),
        ),
      ),
    ).then((_) => _loadBookings());
  }

  void _openReview(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          studioId: booking.studioId,
          bookingId: booking.id,
        ),
      ),
    ).then((_) => _loadBookings());
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.danger),
            const SizedBox(height: 16),
            const Text(
              'Terjadi kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(_error ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBookings, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, bool isUpcoming) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUpcoming ? Icons.calendar_today : Icons.history,
                size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'Tidak ada booking mendatang' : 'Belum ada riwayat booking',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
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

    final customerName = context.watch<AuthProvider>().user?.name ?? '';

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
              bookingCode: booking.bookingCode,
              customerName: customerName,
              studioName: booking.studio?.name,
              roomName: booking.room?.name,
              date: booking.date,
              startTime: booking.startTime,
              endTime: booking.endTime,
              status: booking.status,
              totalPrice: booking.total,
              onTap: () => _showBookingDetail(booking),
              onCancel: () => _cancelBooking(booking),
              onPay: booking.status == 'pending' || booking.status == 'awaiting_payment'
                  ? () => _openPayment(booking)
                  : null,
              onReview: booking.status == 'completed' ? () => _openReview(booking) : null,
            ),
          );
        },
      ),
    );
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.studio?.name ?? 'Booking',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow('Kode', booking.bookingCode),
            _detailRow('Ruangan', booking.room?.name ?? '-'),
            _detailRow('Tanggal', booking.bookingDate),
            _detailRow('Jam', '${booking.startTime} - ${booking.endTime}'),
            _detailRow('Status', booking.statusLabel),
            _detailRow('Total', booking.formattedTotal),
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _detailRow('Catatan', booking.notes!),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
