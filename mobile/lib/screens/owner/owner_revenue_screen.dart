import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class OwnerRevenueScreen extends StatefulWidget {
  const OwnerRevenueScreen({super.key});

  @override
  State<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends State<OwnerRevenueScreen> {
  Map<String, dynamic> _revenueSummary = {};
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _topStudios = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadRevenue();
  }

  Future<void> _loadRevenue() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      
      // Fetch owner revenue data
      final revenueResponse = await apiService.get(ApiConstants.ownerRevenue);
      
      if (revenueResponse['success'] == true) {
        final data = revenueResponse['data'];
        
        setState(() {
          _revenueSummary = {
            'total_revenue': data['total_revenue'] ?? 0,
            'this_month': data['this_month'] ?? 0,
            'last_month': data['last_month'] ?? 0,
            'this_year': data['this_year'] ?? 0,
            'pending': data['pending'] ?? 0,
            'refunded': data['refunded'] ?? 0,
          };

          // Parse monthly revenue data
          final monthlyData = data['monthly_revenue'] ?? [];
          _monthlyRevenue = List<Map<String, dynamic>>.from(monthlyData.map((item) => {
            'month': item['month'] ?? '',
            'revenue': item['revenue'] ?? 0,
          }));

          // Parse top studios
          final studiosData = data['top_studios'] ?? [];
          _topStudios = List<Map<String, dynamic>>.from(studiosData.map((studio) => {
            'name': studio['name'] ?? '',
            'revenue': studio['revenue'] ?? 0,
            'bookings': studio['bookings'] ?? 0,
          }));

          // Parse recent transactions
          final transactionsData = data['recent_transactions'] ?? [];
          _recentTransactions = List<Map<String, dynamic>>.from(transactionsData.map((tx) => {
            'booking_code': tx['booking_code'] ?? '',
            'customer_name': tx['customer_name'] ?? '',
            'date': tx['date'] ?? '',
            'amount': tx['amount'] ?? 0,
            'status': tx['status'] ?? '',
          }));

          _isLoading = false;
        });
      } else {
        throw Exception(revenueResponse['message'] ?? 'Failed to load revenue');
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
        title: const Text('Pendapatan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadRevenue();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'daily',
                child: Text('Harian'),
              ),
              const PopupMenuItem(
                value: 'weekly',
                child: Text('Mingguan'),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Text('Bulanan'),
              ),
              const PopupMenuItem(
                value: 'yearly',
                child: Text('Tahunan'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRevenue,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadRevenue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRevenueSummary(),
                        const SizedBox(height: 20),
                        _buildMonthlyChart(),
                        const SizedBox(height: 20),
                        _buildTopStudios(),
                        const SizedBox(height: 20),
                        _buildRecentTransactions(),
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
            onPressed: _loadRevenue,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Pendapatan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Pendapatan',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['total_revenue'] ?? 0),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Bulan Ini',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['this_month'] ?? 0),
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Bulan Lalu',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['last_month'] ?? 0),
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Tahun Ini',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['this_year'] ?? 0),
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['pending'] ?? 0),
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Refund',
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(_revenueSummary['refunded'] ?? 0),
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan Bulanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _monthlyRevenue.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _monthlyRevenue.map((data) {
                      final revenue = data['revenue'] as int;
                      final maxRevenue = _monthlyRevenue
                          .map((d) => d['revenue'] as int)
                          .reduce((a, b) => a > b ? a : b);
                      final height = (revenue / maxRevenue) * 150;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.compact(
                                  locale: 'id',
                                ).format(revenue),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['month'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStudios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Studio Terlaris',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_topStudios.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Belum ada data studio',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_topStudios.map((studio) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            studio['name'][studio['name'].length - 1],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studio['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${studio['bookings']} booking',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp',
                          decimalDigits: 0,
                        ).format(studio['revenue']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all transactions
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _recentTransactions.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada transaksi terakhir',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Column(
                  children: _recentTransactions.map((tx) => _buildTransactionItem(
                    tx['booking_code'],
                    tx['customer_name'],
                    tx['date'],
                    tx['amount'],
                    tx['status'],
                  )).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String bookingCode,
    String customerName,
    String date,
    int amount,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookingCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: status == 'completed'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'completed' ? 'Selesai' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    color: status == 'completed' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
