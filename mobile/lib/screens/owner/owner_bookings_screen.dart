import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/booking_card.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final statuses = ['all', 'pending', 'confirmed', 'completed'];
    setState(() {
      _selectedStatus = statuses[_tabController.index];
    });
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      
      // Fetch owner bookings from API
      String endpoint = '${ApiConstants.ownerBookings}';
      if (_selectedStatus != 'all') {
        endpoint += '?status=$_selectedStatus';
      }
      
      final response = await apiService.get(endpoint);
      
      if (response['success'] == true) {
        final bookingsData = response['data'] ?? [];
        
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(bookingsData.map((booking) => {
            'id': booking['id'],
            'booking_code': booking['booking_code'] ?? '',
            'customer_name': booking['customer_name'] ?? 'Unknown',
            'studio_name': booking['studio_name'] ?? '',
            'room_name': booking['room_name'] ?? '',
            'date': booking['date'] ?? '',
            'start_time': booking['start_time'] ?? '',
            'end_time': booking['end_time'] ?? '',
            'status': booking['status'] ?? 'pending',
            'total_price': booking['total_price'] ?? 0,
          }));
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

  Future<void> _confirmBooking(int bookingId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post('${ApiConstants.ownerBookingConfirm(bookingId)}');
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dikonfirmasi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(response['message'] ?? 'Failed to confirm booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengkonfirmasi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeBooking(int bookingId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post('${ApiConstants.ownerBookingComplete(bookingId)}');
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil diselesaikan'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        throw Exception(response['message'] ?? 'Failed to complete booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedStatus == 'all') {
      return _bookings;
    }
    return _bookings.where((b) => b['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Kelola Booking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Semua (${_bookings.length})'),
            Tab(text: 'Pending (${_bookings.where((b) => b['status'] == 'pending').length})'),
            Tab(text: 'Confirmed (${_bookings.where((b) => b['status'] == 'confirmed').length})'),
            Tab(text: 'Selesai (${_bookings.where((b) => b['status'] == 'completed').length})'),
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
              : _filteredBookings.isEmpty
                  ? _buildEmptyWidget()
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _filteredBookings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                _showBookingDetail(booking);
                              },
                            ),
                          );
                        },
                      ),
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada booking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Booking ${_selectedStatus == 'all' ? '' : 'dengan status $_selectedStatus'}\ntidak ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingDetailSheet(
        booking: booking,
        onConfirm: () {
          _confirmBooking(booking['id']);
          Navigator.pop(context);
        },
        onComplete: () {
          _completeBooking(booking['id']);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;

  const _BookingDetailSheet({
    required this.booking,
    required this.onConfirm,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Booking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Kode Booking', booking['booking_code']),
                  _buildDetailRow('Pelanggan', booking['customer_name']),
                  _buildDetailRow('Studio', booking['studio_name']),
                  _buildDetailRow('Ruangan', booking['room_name']),
                  _buildDetailRow('Tanggal', booking['date']),
                  _buildDetailRow('Waktu', '${booking['start_time']} - ${booking['end_time']}'),
                  _buildDetailRow('Status', _getStatusText(booking['status'])),
                  _buildDetailRow(
                    'Total Harga',
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp',
                      decimalDigits: 0,
                    ).format(booking['total_price']),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          if (booking['status'] == 'pending')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Konfirmasi'),
                    ),
                  ),
                ],
              ),
            ),
          if (booking['status'] == 'confirmed')
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Selesaikan Booking'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '⏳ Menunggu Pembayaran';
      case 'awaiting_payment':
        return '💳 Menunggu Pembayaran';
      case 'paid':
        return '✅ Sudah Dibayar';
      case 'confirmed':
        return '✅ Dikonfirmasi';
      case 'ongoing':
        return '🎤 Sedang Berlangsung';
      case 'completed':
        return '✅ Selesai';
      case 'cancelled':
        return '❌ Dibatalkan';
      default:
        return status;
    }
  }
}
