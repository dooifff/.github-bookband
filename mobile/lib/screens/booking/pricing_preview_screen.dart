import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/studio_repository.dart';

class PricingPreviewScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const PricingPreviewScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<PricingPreviewScreen> createState() => _PricingPreviewScreenState();
}

class _PricingPreviewScreenState extends State<PricingPreviewScreen> {
  List<Map<String, dynamic>> _pricingData = [];
  bool _isLoading = true;
  String? _error;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  @override
  void initState() {
    super.initState();
    _loadPricingPreview();
  }

  Future<void> _loadPricingPreview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studioRepository = context.read<StudioRepository>();
      final result = await studioRepository.getPricingPreview(
        widget.roomId,
        DateFormat('yyyy-MM-dd').format(_startDate),
        DateFormat('yyyy-MM-dd').format(_endDate),
      );

      setState(() {
        _pricingData = List<Map<String, dynamic>>.from(result['pricing'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPricingPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Prediksi Harga'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Pilih Rentang Tanggal',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateRangeHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildPricingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.meeting_room, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Ubah'),
          ),
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
            onPressed: _loadPricingPreview,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingList() {
    if (_pricingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.price_check, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data harga',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pricingData.length,
      itemBuilder: (context, index) {
        final pricing = _pricingData[index];
        return _buildPricingCard(pricing);
      },
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> pricing) {
    final multiplier = pricing['multiplier'] ?? 1.0;
    final basePrice = pricing['base_price'] ?? 0;
    final dynamicPrice = pricing['dynamic_price'] ?? 0;
    final isDiscount = multiplier < 1;
    final isSurcharge = multiplier > 1;
    final date = DateTime.parse(pricing['date']);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEEE', 'id').format(date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy', 'id').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              _buildPriceTag(multiplier, isDiscount, isSurcharge),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPriceInfo(
                  'Harga Normal',
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(basePrice),
                  Colors.grey,
                ),
              ),
              Container(
                width: 40,
                height: 1,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildPriceInfo(
                  'Harga Dynamic',
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(dynamicPrice),
                  isDiscount
                      ? Colors.green
                      : isSurcharge
                          ? Colors.orange
                          : Colors.blue,
                ),
              ),
            ],
          ),
          if (pricing['applied_rules'] != null &&
              (pricing['applied_rules'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aturan yang diterapkan:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...((pricing['applied_rules'] as List).map((rule) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${rule['name']} (${rule['multiplier']}x)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceTag(double multiplier, bool isDiscount, bool isSurcharge) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (isDiscount) {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      text = '-${((1 - multiplier) * 100).toStringAsFixed(0)}%';
    } else if (isSurcharge) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      text = '+${((multiplier - 1) * 100).toStringAsFixed(0)}%';
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey;
      text = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriceInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
