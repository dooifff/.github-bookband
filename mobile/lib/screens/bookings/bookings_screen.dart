import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get(ApiConstants.bookings);
      
      if (response['success'] == true) {
        final allBookings = List<Map<String, dynamic>>.from(response['data'] ?? []);
        
        final now = DateTime.now();
        setState(() {
          _upcomingBookings = allBookings.where((b) {
            final date = DateTime.tryParse(b['date'] ?? '');
            return date != null && date.isAfter(now) && 
                   (b['status'] == 'pending' || b['status'] == 'confirmed' || b['status'] == 'paid');
          }).toList();
          
          _pastBookings = allBookings.where((b) {
            final date = DateTime.tryParse(b['date'] ?? '');
            return date != null && date.isBefore(now) || 
                   b['status'] == 'completed' || b['status'] == 'cancelled';
          }).toList();
          
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load bookings');
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Saya'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Mendatang (${_upcomingBookings.length})'),
            Tab(text: 'Riwayat (${_pastBookings.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            child: const Text('Coba Lagi'),
          ),
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
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'Tidak ada booking mendatang' : 'Belum ada riwayat booking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming ? 'Booking akan muncul di sini' : 'Riwayat booking akan muncul di sini',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
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
