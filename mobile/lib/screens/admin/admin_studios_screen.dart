import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminStudiosScreen extends StatefulWidget {
  const AdminStudiosScreen({super.key});

  @override
  State<AdminStudiosScreen> createState() => _AdminStudiosScreenState();
}

class _AdminStudiosScreenState extends State<AdminStudiosScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  String _filter = 'all';
  List<Map<String, dynamic>> _studios = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final query = <String, dynamic>{
        'page': _page,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
        if (_filter == 'verified') 'is_verified': 1,
        if (_filter == 'unverified') 'is_verified': 0,
        if (_filter == 'active') 'is_active': 1,
        if (_filter == 'inactive') 'is_active': 0,
      };
      final response = await apiService.get(ApiConstants.adminStudios, queryParameters: query);
      if (response['success'] == true) {
        final rawItems = response['data'] is List ? response['data'] : <dynamic>[];
        final meta = response['meta'] is Map ? Map<String, dynamic>.from(response['meta']) : <String, dynamic>{};
        setState(() {
          _studios = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
          _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
          _total = meta['total'] is int ? meta['total'] : 0;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat studio');
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
    _loadStudios();
  }

  void _onFilter(String? value) {
    setState(() => _filter = value ?? 'all');
    _page = 1;
    _loadStudios();
  }

  void _loadMore() {
    if (_page >= _lastPage || _isLoading) return;
    setState(() => _page++);
    _loadStudios();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Studios',
      subtitle: 'Kelola semua studio di platform',
      refreshable: true,
      onRefresh: _loadStudios,
      child: Column(
        children: [
          AdminFilterBar(
            searchController: _searchController,
            onSearch: _onSearch,
            onFilterChanged: _onFilter,
            filterValue: _filter,
            filterLabel: 'Status',
            filterOptions: const [
              ('all', 'Semua Status'),
              ('verified', 'Terverifikasi'),
              ('unverified', 'Belum Diverifikasi'),
              ('active', 'Aktif'),
              ('inactive', 'Nonaktif'),
            ],
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: $_total studio',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadStudios)
                    : _studios.isEmpty
                        ? const AdminEmptyState(
                            message: 'Tidak ada studio ditemukan')
                        : RefreshIndicator(
                            onRefresh: _loadStudios,
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
                                itemCount: _studios.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildStudioCard(_studios[index]),
                              ),
                            ),
                          ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildStudioCard(Map<String, dynamic> studio) {
    final owner = studio['owner'] is Map
        ? Map<String, dynamic>.from(studio['owner'])
        : <String, dynamic>{};
    final subscription = studio['subscription'] is Map
        ? Map<String, dynamic>.from(studio['subscription'])
        : <String, dynamic>{};
    return AdminTapCard(
      onTap: () => _showStudioDetail(studio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined,
                    size: 20, color: AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${studio['name'] ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${parseNum(studio['rooms_count'] ?? 0).toInt()} ruangan',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  AdminBadge(
                    studio['is_verified'] == true
                        ? 'Terverifikasi'
                        : 'Belum Verified',
                    studio['is_verified'] == true
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                  const SizedBox(width: 4),
                  AdminBadge(
                    studio['is_active'] == true ? 'Aktif' : 'Nonaktif',
                    studio['is_active'] == true
                        ? AppTheme.success
                        : AppTheme.textMuted,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${studio['city'] ?? ''}${studio['city'] != null && studio['city'] != '' ? ' · ' : ''}${owner['name'] ?? 'Pemilik tidak diketahui'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              if (parseNum(studio['average_rating']).toDouble() > 0)
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppTheme.warning),
                    const SizedBox(width: 2),
                    Text(
                      parseNum(studio['average_rating']).toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' (${parseNum(studio['total_reviews']).toInt()})',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
            ],
          ),
          if (subscription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: subscriptionBadge(subscription),
            ),
        ],
      ),
    );
  }

  Widget subscriptionBadge(Map<String, dynamic> sub) {
    final status = '${sub['status']}';
    if (status == 'active') {
      return AdminBadge(
        'Langganan s.d. ${formatDate(sub['expires_at'], long: false)}',
        AppTheme.success,
      );
    }
    if (status == 'expired') {
      final warning = parseNum(sub['warning_level']).toInt();
      if (warning >= 2) {
        return const AdminBadge('⚠️ Peringatan akhir - akan dihapus', AppTheme.danger);
      }
      if (warning >= 1) {
        return const AdminBadge('⚠️ Peringatan 1 terkirim', AppTheme.warning);
      }
      return const AdminBadge('Masa aktif berakhir', AppTheme.warning);
    }
    if (status == 'removed') {
      return const AdminBadge('Dihapus (langganan)', AppTheme.danger);
    }
    return const AdminBadge('Tanpa langganan', AppTheme.textMuted);
  }

  Widget _buildPaginationBar() {
    if (_studios.isEmpty && _page <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _loadStudios();
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
                    _loadStudios();
                  }
                : null,
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStudioDetail(Map<String, dynamic> studio) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudioDetailSheet(
        listItem: studio,
        onChanged: _loadStudios,
      ),
    );
  }
}

class _StudioDetailSheet extends StatefulWidget {
  final Map<String, dynamic> listItem;
  final VoidCallback onChanged;

  const _StudioDetailSheet({required this.listItem, required this.onChanged});

  @override
  State<_StudioDetailSheet> createState() => _StudioDetailSheetState();
}

class _StudioDetailSheetState extends State<_StudioDetailSheet> {
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
      final response = await apiService
          .get(ApiConstants.adminStudioDetail(widget.listItem['id']));
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

  @override
  Widget build(BuildContext context) {
    final studio = _detail ?? widget.listItem;
    final owner = studio['owner'] is Map
        ? Map<String, dynamic>.from(studio['owner'])
        : <String, dynamic>{};
    final rooms = studio['rooms'] is List ? studio['rooms'] as List : <dynamic>[];

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
                const Text(
                  'Detail Studio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadDetail,
                ),
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
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.storefront,
                                      size: 24, color: AppTheme.accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${studio['name'] ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        '${studio['address'] ?? ''}${studio['address'] != null && studio['address'] != '' ? ', ' : ''}${studio['city'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                AdminBadge(
                                  studio['is_verified'] == true
                                      ? '✓ Terverifikasi'
                                      : '⏳ Belum Verified',
                                  studio['is_verified'] == true
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                AdminBadge(
                                  studio['is_active'] == true
                                      ? 'Aktif'
                                      : 'Nonaktif',
                                  studio['is_active'] == true
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
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
                                      'Pemilik', '${owner['name'] ?? '-'}'),
                                  AdminDetailRow(
                                      'Email', '${owner['email'] ?? '-'}'),
                                  AdminDetailRow(
                                      'Rating',
                                      '${parseNum(studio['average_rating']).toStringAsFixed(1)} ★ (${parseNum(studio['total_reviews']).toInt()} ulasan)'),
                                ],
                              ),
                            ),
                            if (studio['phone'] != null ||
                                studio['email'] != null) ...[
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
                                    if (studio['phone'] != null)
                                      AdminDetailRow('Telepon',
                                          '${studio['phone'] ?? '-'}'),
                                    if (studio['email'] != null)
                                      AdminDetailRow('Email',
                                          '${studio['email'] ?? '-'}'),
                                  ],
                                ),
                              ),
                            ],
                            if (studio['description'] != null &&
                                '${studio['description']}'.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${studio['description']}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              'Ruangan (${rooms.length})',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            if (rooms.isEmpty)
                              Text(
                                'Tidak ada ruangan',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13),
                              )
                            else
                              ...rooms.map((r) {
                                final room = Map<String, dynamic>.from(r);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.meeting_room_outlined,
                                            size: 18, color: AppTheme.accent),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${room['name'] ?? '-'}',
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          'Kapasitas: ${parseNum(room['capacity']).toInt()} orang',
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          idr(parseNum(room['price_per_hour'])) +
                                              '/jam',
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.accent),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
          ),
          if (_detail != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _toggleVerify(context, _detail!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _detail!['is_verified'] == true
                                ? AppTheme.warning
                                : AppTheme.success,
                            side: BorderSide(
                              color: _detail!['is_verified'] == true
                                  ? AppTheme.warning
                                  : AppTheme.success,
                            ),
                          ),
                          child: Text(
                            _detail!['is_verified'] == true
                                ? 'Batalkan Verifikasi'
                                : 'Verifikasi Studio',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _toggleActive(context, _detail!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _detail!['is_active'] == true
                                ? AppTheme.danger
                                : AppTheme.success,
                            side: BorderSide(
                              color: _detail!['is_active'] == true
                                  ? AppTheme.danger
                                  : AppTheme.success,
                            ),
                          ),
                          child: Text(
                            _detail!['is_active'] == true
                                ? 'Nonaktifkan'
                                : 'Aktifkan',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _openSubscriptionSheet(context, _detail!),
                      icon: const Icon(Icons.subscriptions_outlined, size: 18),
                      label: const Text('Atur Langganan Studio'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleVerify(
      BuildContext context, Map<String, dynamic> studio) async {
    final verified = studio['is_verified'] == true;
    final ok = await _confirm(
        '${verified ? 'Batalkan verifikasi' : 'Verifikasi'} studio "${studio['name']}"?');
    if (!ok) return;
    final apiService = ApiService();
    try {
      final response = await apiService.post(
        verified
            ? ApiConstants.adminStudioUnverify(studio['id'])
            : ApiConstants.adminStudioVerify(studio['id']),
      );
      if (context.mounted) {
        if (response['success'] == true) {
          _snack(response['message'] ?? 'Berhasil', AppTheme.success);
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

  Future<void> _toggleActive(
      BuildContext context, Map<String, dynamic> studio) async {
    final active = studio['is_active'] == true;
    final ok = await _confirm(
        '${active ? 'Nonaktifkan' : 'Aktifkan'} studio "${studio['name']}"?');
    if (!ok) return;
    final apiService = ApiService();
    try {
      final response = await apiService.post(
        active
            ? ApiConstants.adminStudioDeactivate(studio['id'])
            : ApiConstants.adminStudioActivate(studio['id']),
      );
      if (context.mounted) {
        if (response['success'] == true) {
          _snack(response['message'] ?? 'Berhasil', AppTheme.success);
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

  Future<void> _openSubscriptionSheet(
      BuildContext context, Map<String, dynamic> studio) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionSheet(studio: studio),
    );
    if (saved == true) {
      widget.onChanged();
      _loadDetail();
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

class _SubscriptionSheet extends StatefulWidget {
  final Map<String, dynamic> studio;

  const _SubscriptionSheet({required this.studio});

  @override
  State<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<_SubscriptionSheet> {
  late String _status;
  DateTime? _expiresAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final sub = widget.studio['subscription'] is Map
        ? Map<String, dynamic>.from(widget.studio['subscription'])
        : <String, dynamic>{};
    _status = '${sub['status']}' == 'active' ? 'active' : 'none';
    _expiresAt = parseDate(sub['expires_at']) ??
        DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final api = ApiConstants.adminStudioSubscription(widget.studio['id']);
      final response = await apiService.post(
        api,
        data: {
          'status': _status,
          if (_status == 'active')
            'expires_at':
                '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')}'
            else
              'expires_at': null,
        },
      );
      if (context.mounted) {
        if (response['success'] == true) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _saving = false;
            _error = response['message'] ?? 'Gagal menyimpan';
          });
        }
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            secondary: AppTheme.accent,
            surface: AppTheme.surfaceLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const Text(
              'Atur Langganan Studio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.studio['name']}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text('Error: $_error',
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12.5)),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Berlangganan (aktif)')),
                DropdownMenuItem(value: 'none', child: Text('Tidak berlangganan')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'none'),
            ),
            if (_status == 'active') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Masa Aktif Berakhir Pada'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Text(formatDate(_expiresAt, long: true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih tanggal hari ini atau kemarin untuk menguji cron peringatan (status jadi expired).',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}