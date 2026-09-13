import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminSubscribersScreen extends StatefulWidget {
  const AdminSubscribersScreen({super.key});

  @override
  State<AdminSubscribersScreen> createState() => _AdminSubscribersScreenState();
}

class _AdminSubscribersScreenState extends State<AdminSubscribersScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  String _status = 'all';
  List<Map<String, dynamic>> _owners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
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
          .get(ApiConstants.adminSubscriptions, queryParameters: query);
      if (response['success'] == true) {
        final rawItems =
            response['data'] is List ? response['data'] : <dynamic>[];
        final meta = response['meta'] is Map
            ? Map<String, dynamic>.from(response['meta'])
            : <String, dynamic>{};
        setState(() {
          _owners = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
          _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
          _total = meta['total'] is int ? meta['total'] : 0;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat subscribers');
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
    _loadSubscriptions();
  }

  void _onFilter(String? value) {
    setState(() => _status = value ?? 'all');
    _page = 1;
    _loadSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Subscribers',
      subtitle: 'Semua owner studio yang berlangganan',
      refreshable: true,
      onRefresh: _loadSubscriptions,
      child: Column(
        children: [
          _buildStatCards(),
          AdminFilterBar(
            searchController: _searchController,
            onSearch: _onSearch,
            onFilterChanged: _onFilter,
            filterValue: _status,
            filterLabel: 'Status',
            filterOptions: const [
              ('all', 'Semua Status'),
              ('active', 'Aktif'),
              ('expired', 'Expired'),
              ('none', 'Tidak Aktif'),
            ],
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: $_total owner',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadSubscriptions)
                    : _owners.isEmpty
                        ? const AdminEmptyState(
                            message: 'Belum ada owner studio')
                        : RefreshIndicator(
                            onRefresh: _loadSubscriptions,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _owners.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  _buildOwnerCard(_owners[index]),
                            ),
                          ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    int active = 0, expired = 0, none = 0;
    for (final o in _owners) {
      switch ('${o['subscription_status']}') {
        case 'active':
          active++;
          break;
        case 'expired':
          expired++;
          break;
        default:
          none++;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Total Owner',
                  value: '$_total',
                  icon: Icons.group_outlined,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminStatCard(
                  label: 'Aktif',
                  value: '$active',
                  icon: Icons.check_circle_outline,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  label: 'Expired',
                  value: '$expired',
                  icon: Icons.error_outline,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminStatCard(
                  label: 'Tidak Aktif',
                  value: '$none',
                  icon: Icons.not_interested,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(Map<String, dynamic> owner) {
    final ownerInfo = owner['owner'] is Map
        ? Map<String, dynamic>.from(owner['owner'])
        : <String, dynamic>{};
    final studios = owner['studios'] is List
        ? List<Map<String, dynamic>>.from(
            owner['studios'].map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];
    final status = '${owner['subscription_status']}';

    return AdminTapCard(
      onTap: () => _showOwnerDetail(owner),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: subscriptionStatusColor(status).withOpacity(0.15),
                child: Text(
                  '${ownerInfo['name']?.toString().isNotEmpty == true ? ownerInfo['name'][0].toUpperCase() : '?'}',
                  style: TextStyle(
                    color: subscriptionStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ownerInfo['name'] ?? '-'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${ownerInfo['email'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AdminBadge(
                    subscriptionStatusLabel(status),
                    subscriptionStatusColor(status),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires: ${owner['subscription_expires_at'] != null ? formatDate(owner['subscription_expires_at'], long: false) : '-'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...studios.take(2).map((s) {
                      final sStatus = '${s['subscription_status']}';
                      return AdminBadge(
                        '${s['name']}',
                        subscriptionStatusColor(sStatus),
                      );
                    }),
                    if (studios.length > 2)
                      AdminBadge(
                        '+${studios.length - 2} lagi',
                        AppTheme.textMuted,
                      ),
                    if (studios.isEmpty)
                      Text(
                        'Belum ada studio',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                daysLeftText(owner['subscription_expires_at']),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: daysLeftColor(owner['subscription_expires_at']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_owners.isEmpty && _page <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 1
                ? () {
                    setState(() => _page--);
                    _loadSubscriptions();
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
                    _loadSubscriptions();
                  }
                : null,
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOwnerDetail(Map<String, dynamic> owner) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OwnerSubscriptionSheet(
        listItem: owner,
        onChanged: _loadSubscriptions,
      ),
    );
  }
}

class _OwnerSubscriptionSheet extends StatefulWidget {
  final Map<String, dynamic> listItem;
  final VoidCallback onChanged;

  const _OwnerSubscriptionSheet(
      {required this.listItem, required this.onChanged});

  @override
  State<_OwnerSubscriptionSheet> createState() =>
      _OwnerSubscriptionSheetState();
}

class _OwnerSubscriptionSheetState extends State<_OwnerSubscriptionSheet> {
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
          .get(ApiConstants.adminSubscriptionDetail(widget.listItem['id']));
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
    final owner = _detail ?? widget.listItem;
    final ownerInfo = owner['owner'] is Map
        ? Map<String, dynamic>.from(owner['owner'])
        : <String, dynamic>{};
    final studios = owner['studios'] is List
        ? List<Map<String, dynamic>>.from(
            owner['studios'].map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];
    final status = '${owner['subscription_status']}';

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
                  'Detail Subscriber',
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
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      subscriptionStatusColor(status)
                                          .withOpacity(0.15),
                                  child: Text(
                                    '${ownerInfo['name']?.toString().isNotEmpty == true ? ownerInfo['name'][0].toUpperCase() : '?'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: subscriptionStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ownerInfo['name'] ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        '${ownerInfo['email'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppTheme.textSecondary),
                                      ),
                                      if (ownerInfo['phone'] != null &&
                                          '${ownerInfo['phone']}'.isNotEmpty)
                                        Text(
                                          '${ownerInfo['phone']}',
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppTheme.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AdminBadge(
                                      subscriptionStatusLabel(status),
                                      subscriptionStatusColor(status),
                                    ),
                                    const SizedBox(height: 4),
                                    AdminBadge(
                                      '${parseNum(owner['total_studios']).toInt()} studio',
                                      AppTheme.info,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const AdminSectionTitle('DAFTAR STUDIO'),
                            const SizedBox(height: 10),
                            if (studios.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'Owner ini belum memiliki studio',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ...studios.map((s) {
                                final sStatus = '${s['subscription_status']}';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
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
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.storefront_outlined,
                                                size: 18,
                                                color: AppTheme.accent),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${s['name'] ?? '-'}',
                                                style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        AppTheme.textPrimary),
                                              ),
                                            ),
                                            Text(
                                              '${parseNum(s['room_count']).toInt()} ruangan',
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            AdminBadge(
                                              subscriptionStatusLabel(sStatus),
                                              subscriptionStatusColor(sStatus),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Expires: ${s['subscription_expires_at'] != null ? formatDate(s['subscription_expires_at'], long: false) : '-'}',
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              daysLeftText(
                                                  s['subscription_expires_at']),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: daysLeftColor(s[
                                                    'subscription_expires_at']),
                                              ),
                                            ),
                                            const Spacer(),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _openEditSubscription(s),
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16),
                                              label: const Text('Atur'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
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
                                      'Total Studio',
                                      '${parseNum(owner['total_studios']).toInt()}'),
                                  AdminDetailRow(
                                      'Studio Aktif',
                                      '${studios.where((s) => '${s['subscription_status']}' == 'active').length}'),
                                  AdminDetailRow(
                                      'Bergabung',
                                      formatDate(owner['created_at']),
                                      valueColor: AppTheme.textSecondary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditSubscription(Map<String, dynamic> studio) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSubscriptionSheet(studio: studio),
    );
    if (saved == true) {
      widget.onChanged();
      _loadDetail();
    }
  }
}

class _EditSubscriptionSheet extends StatefulWidget {
  final Map<String, dynamic> studio;

  const _EditSubscriptionSheet({required this.studio});

  @override
  State<_EditSubscriptionSheet> createState() => _EditSubscriptionSheetState();
}

class _EditSubscriptionSheetState extends State<_EditSubscriptionSheet> {
  late String _status;
  DateTime? _expiresAt;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = '${widget.studio['subscription_status']}' == 'active'
        ? 'active'
        : 'none';
    _expiresAt = parseDate(widget.studio['subscription_expires_at']) ??
        DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        ApiConstants.adminStudioSubscription(widget.studio['id']),
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
              'Atur Langganan',
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
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'none', child: Text('Tidak Aktif')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'none'),
            ),
            if (_status == 'active') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration:
                      const InputDecoration(labelText: 'Tanggal Kadaluarsa'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Text(formatDate(_expiresAt, long: true)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, false),
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