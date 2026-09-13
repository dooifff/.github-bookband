import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../admin/admin_widgets.dart'
    show parseNum, formatDate, bookingStatusLabel, bookingStatusColor, idr;
import 'owner_widgets.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  final _searchController = TextEditingController();
  final _statusController = TextEditingController(text: 'all');
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  static const _statusFilters = [
    ('all', 'Semua'),
    ('pending', 'Menunggu'),
    ('awaiting_payment', 'Menunggu Bayar'),
    ('paid', 'Dibayar'),
    ('confirmed', 'Dikonfirmasi'),
    ('ongoing', 'Berlangsung'),
    ('completed', 'Selesai'),
    ('cancelled', 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statusController.dispose();
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
        if (_statusController.text != 'all') 'status': _statusController.text,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      };
      final response = await apiService
          .get(ApiConstants.ownerBookings, queryParameters: query);
      final rawItems =
          response['data'] is List ? response['data'] : <dynamic>[];
      final meta = response['meta'] is Map
          ? Map<String, dynamic>.from(response['meta'])
          : <String, dynamic>{};
      setState(() {
        _bookings = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
        _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
        _total = meta['total'] is int ? meta['total'] : 0;
        _isLoading = false;
      });
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

  void _selectStatus(String value) {
    if (_statusController.text == value) return;
    _statusController.text = value;
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
    return OwnerScaffold(
      title: 'Bookings',
      subtitle: 'Pemesanan studio milik Anda',
      refreshable: true,
      onRefresh: _loadBookings,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari kode booking, nama, studio…',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceLight,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (value, label) = _statusFilters[index];
                final selected = _statusController.text == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => _selectStatus(value),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  backgroundColor: AppTheme.surfaceLight,
                  selectedColor: AppTheme.accent,
                  side: BorderSide(
                    color: selected ? AppTheme.accent : AppTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              },
            ),
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
                : _error != null
                    ? _OwnerError(message: _error!, onRetry: _loadBookings)
                    : _bookings.isEmpty
                        ? const _OwnerEmpty(message: 'Tidak ada booking ditemukan')
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
                                    _BookingCard(
                                  booking: _bookings[index],
                                  onTap: () =>
                                      _showBookingDetail(_bookings[index]),
                                ),
                              ),
                            ),
                          ),
          ),
          _buildPaginationBar(),
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
      builder: (_) => _OwnerBookingDetail(
        booking: booking,
        onChanged: _loadBookings,
      ),
    );
  }
}

class _OwnerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OwnerError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.danger),
            const SizedBox(height: 12),
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

class _OwnerEmpty extends StatelessWidget {
  final String message;

  const _OwnerEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_note_outlined,
              size: 44, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
    final total = _totalOf(booking);
    final userName = '${user['name'] ?? '-'}';
    final studioName = '${studio['name'] ?? '-'}';
    final roomName = '${room['name'] ?? ''}';
    final timeRange =
        '${formatClock(booking['start_time'])} – ${formatClock(booking['end_time'])}';

    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${booking['booking_code'] ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  OwnerBadge(bookingStatusLabel(status),
                      bookingStatusColor(status)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OwnerAvatar(name: userName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                roomName.isNotEmpty ? '$studioName · $roomName' : studioName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatDate(booking['date'], long: false)} · $timeRange',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ),
                  Text(
                    idr(total),
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
        ),
      ),
    );
  }

  static num _totalOf(Map<String, dynamic> booking) {
    final pricing = booking['pricing'] is Map
        ? Map<String, dynamic>.from(booking['pricing'])
        : <String, dynamic>{};
    if (pricing.isNotEmpty) return parseNum(pricing['total']);
    return parseNum(booking['total']);
  }
}

class _OwnerBookingDetail extends StatefulWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onChanged;

  const _OwnerBookingDetail({
    required this.booking,
    required this.onChanged,
  });

  @override
  State<_OwnerBookingDetail> createState() => _OwnerBookingDetailState();
}

class _OwnerBookingDetailState extends State<_OwnerBookingDetail> {
  Map<String, dynamic> get _booking => widget.booking;

  String get _status => '${_booking['status']}';

  bool get _canConfirm {
    return _status == 'pending' ||
        _status == 'awaiting_payment' ||
        _status == 'paid';
  }

  bool get _canComplete {
    return _status == 'confirmed' || _status == 'ongoing';
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final user = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'])
        : <String, dynamic>{};
    final studio = booking['studio'] is Map
        ? Map<String, dynamic>.from(booking['studio'])
        : <String, dynamic>{};
    final room = booking['room'] is Map
        ? Map<String, dynamic>.from(booking['room'])
        : <String, dynamic>{};
    final pricing = booking['pricing'] is Map
        ? Map<String, dynamic>.from(booking['pricing'])
        : <String, dynamic>{};
    final payment = booking['payment'] is Map
        ? Map<String, dynamic>.from(booking['payment'])
        : null;

    final subtotal = pricing.isNotEmpty
        ? parseNum(pricing['subtotal'] ?? pricing['total'])
        : parseNum(booking['total']);
    final total = pricing.isNotEmpty
        ? parseNum(pricing['total'])
        : parseNum(booking['total']);

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
                OwnerBadge(
                    bookingStatusLabel(_status), bookingStatusColor(_status)),
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
            child: SingleChildScrollView(
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
                                  _DetailRow(
                                    'Pelanggan',
                                    '${user['name'] ?? '-'}\n${user['email'] ?? ''}',
                                  ),
                                  _DetailRow(
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
                                  _DetailRow(
                                      'Jadwal', formatDate(booking['date'])),
                                  _DetailRow(
                                      'Waktu',
                                      '${formatClock(booking['start_time'])} – ${formatClock(booking['end_time'])}'),
                                  _DetailRow(
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
                                  _DetailRow(
                                      'Subtotal', idr(subtotal)),
                                  const Divider(color: AppTheme.border),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  AppTheme.textSecondary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const Spacer(),
                                        Text(
                                          idr(total),
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
                                    _DetailRow(
                                        'Pembayaran',
                                        idr(parseNum(payment['amount']))),
                                    _DetailRow(
                                        'Metode',
                                        '${payment['payment_method'] ?? payment['method'] ?? '-'}'),
                                    _DetailRow(
                                        'Status',
                                        '${payment['status'] ?? '-'}'),
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
                                  border:
                                      Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
          if (_canConfirm || _canComplete)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_canComplete && !_canConfirm)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _completeBooking(context),
                        icon: const Icon(Icons.check_circle_outline,
                            size: 18),
                        label: const Text('Selesaikan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ),
                  if (_canConfirm) ...[
                    if (_canComplete) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmBooking(context),
                        icon: const Icon(Icons.check_circle_outline,
                            size: 18),
                        label: const Text('Konfirmasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.primary,
                        ),
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
        'Konfirmasi booking "${widget.booking['booking_code']}"?');
    if (!ok) return;
    final apiService = ApiService();
    try {
      final response = await apiService
          .post(ApiConstants.ownerBookingConfirm(widget.booking['id']));
      if (context.mounted) {
        if (response['success'] == true) {
          ownerSnack(
              context,
              response['message'] ?? 'Booking dikonfirmasi',
              AppTheme.success);
          if (Navigator.of(context).canPop()) Navigator.pop(context);
          widget.onChanged();
        } else {
          ownerSnack(context,
              response['message'] ?? 'Gagal konfirmasi', AppTheme.danger);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ownerSnack(
            context,
            e.toString().replaceFirst('Exception: ', ''),
            AppTheme.danger);
      }
    }
  }

  Future<void> _completeBooking(BuildContext context) async {
    final ok = await _confirm(
        'Selesaikan booking "${widget.booking['booking_code']}"?');
    if (!ok) return;
    final apiService = ApiService();
    try {
      final response = await apiService
          .post(ApiConstants.ownerBookingComplete(widget.booking['id']));
      if (context.mounted) {
        if (response['success'] == true) {
          ownerSnack(
              context,
              response['message'] ?? 'Booking diselesaikan',
              AppTheme.success);
          if (Navigator.of(context).canPop()) Navigator.pop(context);
          widget.onChanged();
        } else {
          ownerSnack(
              context,
              response['message'] ?? 'Gagal menyelesaikan',
              AppTheme.danger);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ownerSnack(
            context,
            e.toString().replaceFirst('Exception: ', ''),
            AppTheme.danger);
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}