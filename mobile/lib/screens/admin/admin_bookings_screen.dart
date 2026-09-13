import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  String _status = 'all';
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final query = <String, dynamic>{
        'page': _page,
        if (_status != 'all') 'status': _status,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      };
      final response = await apiService
          .get(ApiConstants.adminBookings, queryParameters: query);
      if (response['success'] == true) {
        final rawItems = response['data'] is List ? response['data'] : <dynamic>[];
        final meta = response['meta'] is Map ? Map<String, dynamic>.from(response['meta']) : <String, dynamic>{};
        setState(() {
          _bookings = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
          _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
          _total = meta['total'] is int ? meta['total'] : 0;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat booking');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearch(String value) {
    _page = 1;
    _loadBookings();
  }

  void _onFilter(String? value) {
    setState(() => _status = value ?? 'all');
    _page = 1;
    _loadBookings();
  }

  void _loadMore() {
    if (_page >= _lastPage || _isLoading) return;
    setState(() => _page++);
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Bookings',
      subtitle: 'Kelola semua pemesanan platform',
      refreshable: true,
      onRefresh: _loadBookings,
      child: Column(
        children: [
          AdminFilterBar(
            searchController: _searchController,
            onSearch: _onSearch,
            onFilterChanged: _onFilter,
            filterValue: _status,
            filterLabel: 'Status',
            filterOptions: const [
              ('all', 'Semua Status'),
              ('pending', 'Menunggu'),
              ('awaiting_payment', 'Menunggu Pembayaran'),
              ('confirmed', 'Dikonfirmasi'),
              ('completed', 'Selesai'),
              ('cancelled', 'Dibatalkan'),
            ],
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: $_total booking',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadBookings)
                    : _bookings.isEmpty
                        ? const AdminEmptyState(
                            message: 'Tidak ada booking ditemukan')
                        : RefreshIndicator(
                            onRefresh: _loadBookings,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                        notification.metrics.maxScrollExtent -
                                            200 &&
                                    notification is ScrollUpdateNotification) {
                                  _loadMore();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _bookings.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildBookingCard(_bookings[index]),
                              ),
                            ),
                          ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final user = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'])
        : <String, dynamic>{};
    final studio = booking['studio'] is Map
        ? Map<String, dynamic>.from(booking['studio'])
        : <String, dynamic>{};
    final room = booking['room'] is Map
        ? Map<String, dynamic>.from(booking['room'])
        : <String, dynamic>{};
    final status = '${booking['status']}';

    return AdminTapCard(
      onTap: () => _showBookingDetail(booking),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking['booking_code'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              AdminBadge(bookingStatusLabel(status), bookingStatusColor(status)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${user['name'] ?? '-'} · ${user['email'] ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            '${studio['name'] ?? '-'}${room['name'] != null ? ' · ${room['name']}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDate(booking['date'], long: false)} · ${booking['start_time']} – ${booking['end_time']}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ),
              Text(
                idr(parseNum(booking['total'])),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_bookings.isEmpty && _page <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _loadBookings();
                  }
                : null,
            child: const Text('Sebelumnya'),
          ),
          Text(
            'Halaman $_page dari $_lastPage',
            style:
                const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          TextButton(
            onPressed: _page < _lastPage
                ? () {
                    setState(() => _page++);
                    _loadBookings();
                  }
                : null,
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookingDetail(Map<String, dynamic> booking) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        listItem: booking,
        onChanged: _loadBookings,
      ),
    );
  }
}

class _BookingDetailSheet extends StatefulWidget {
  final Map<String, dynamic> listItem;
  final VoidCallback onChanged;

  const _BookingDetailSheet({required this.listItem, required this.onChanged});

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response =
          await apiService.get(ApiConstants.adminBookingDetail(widget.listItem['id']));
      if (response['success'] == true) {
        setState(() {
          _detail = Map<String, dynamic>.from(response['data']);
          _loading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat detail');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool get _canConfirm {
    final status = '${widget.listItem['status']}';
    return status == 'pending' || status == 'awaiting_payment';
  }

  bool get _canCancel {
    final status = '${widget.listItem['status']}';
    return status == 'pending' ||
        status == 'awaiting_payment' ||
        status == 'paid';
  }

  @override
  Widget build(BuildContext context) {
    final booking = _detail ?? widget.listItem;
    final user = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'])
        : <String, dynamic>{};
    final studio = booking['studio'] is Map
        ? Map<String, dynamic>.from(booking['studio'])
        : <String, dynamic>{};
    final room = booking['room'] is Map
        ? Map<String, dynamic>.from(booking['room'])
        : <String, dynamic>{};
    final payment = booking['payment'] is Map
        ? Map<String, dynamic>.from(booking['payment'])
        : null;
    final status = '${booking['status']}';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking['booking_code'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    Text(
                      'Dibuat: ${formatDate(booking['created_at'])}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                AdminBadge(bookingStatusLabel(status), bookingStatusColor(status)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadDetail)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  AdminDetailRow(
                                    'Pelanggan',
                                    '${user['name'] ?? '-'}\n${user['email'] ?? ''}',
                                  ),
                                  AdminDetailRow(
                                    'Studio',
                                    '${studio['name'] ?? '-'}\n${room['name'] ?? ''}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  AdminDetailRow(
                                      'Jadwal',
                                      '${formatDate(booking['date'])}'),
                                  AdminDetailRow(
                                      'Waktu',
                                      '${booking['start_time']} – ${booking['end_time']}'),
                                  AdminDetailRow(
                                      'Durasi',
                                      '${parseNum(booking['duration_hours'])} jam'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  AdminDetailRow(
                                      'Subtotal', idr(parseNum(booking['subtotal']))),
                                  if (parseNum(booking['discount']) > 0)
                                    AdminDetailRow(
                                        'Diskon',
                                        '-${idr(parseNum(booking['discount']))}',
                                        valueColor: AppTheme.success),
                                  const Divider(color: AppTheme.border),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const Spacer(),
                                        Text(
                                          idr(parseNum(booking['total'])),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: AppTheme.accent,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (payment != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  children: [
                                    AdminDetailRow(
                                        'Pembayaran',
                                        idr(parseNum(payment['amount']))),
                                    AdminDetailRow(
                                        'Metode',
                                        '${payment['payment_method'] ?? payment['method'] ?? '-'}'),
                                    AdminDetailRow(
                                        'Status',
                                        '${payment['status'] ?? '-'}'),
                                  ],
                                ),
                              ),
                            ],
                            if (booking['cancel_reason'] != null &&
                                '${booking['cancel_reason']}'.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.danger.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alasan Pembatalan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.danger),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${booking['cancel_reason']}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (booking['notes'] != null &&
                                '${booking['notes']}'.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Catatan',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${booking['notes']}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
          ),
          if (_canConfirm || _canCancel)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () => _cancelBooking(context),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Batal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                        ),
                      ),
                    ),
                  if (_canConfirm) ...[
                    if (_canCancel) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : () => _confirmBooking(context),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Konfirmasi'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context) async {
    final ok = await _confirm(
        'Konfirmasi booking "${widget.listItem['booking_code']}"?');
    if (!ok) return;
    final apiService = ApiService();
    try {
      final response = await apiService
          .post(ApiConstants.adminBookingConfirm(widget.listItem['id']));
      if (context.mounted) {
        if (response['success'] == true) {
          _snack(response['message'] ?? 'Booking dikonfirmasi', AppTheme.success);
          if (Navigator.of(context).canPop()) Navigator.pop(context);
          widget.onChanged();
        } else {
          _snack(response['message'] ?? 'Gagal', AppTheme.danger);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final reasonController = TextEditingController(text: 'Dibatalkan oleh admin');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Batalkan Booking',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Booking ${widget.listItem['booking_code']} akan dibatalkan.',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alasan Pembatalan'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (reasonController.text.trim().isEmpty) return;
                        Navigator.pop(sheetContext);
                        await _doCancel(reasonController.text.trim());
                        reasonController.dispose();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                      ),
                      child: const Text('Batalkan Booking'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doCancel(String reason) async {
    final apiService = ApiService();
    try {
      final response = await apiService.post(
        ApiConstants.adminBookingCancel(widget.listItem['id']),
        data: {'reason': reason},
      );
      if (context.mounted) {
        if (response['success'] == true) {
          _snack(response['message'] ?? 'Booking dibatalkan', AppTheme.success);
          if (Navigator.of(context).canPop()) Navigator.pop(context);
          widget.onChanged();
        } else {
          _snack(response['message'] ?? 'Gagal', AppTheme.danger);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
      }
    }
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(message,
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}