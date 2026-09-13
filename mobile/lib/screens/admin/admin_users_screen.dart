import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  String _role = 'all';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final query = <String, dynamic>{
        'page': _page,
        if (_role != 'all') 'role': _role,
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
      };
      final response = await apiService.get(ApiConstants.adminUsers, queryParameters: query);
      if (response['success'] == true) {
        final rawItems = response['data'] is List ? response['data'] : <dynamic>[];
        final meta = response['meta'] is Map ? Map<String, dynamic>.from(response['meta']) : <String, dynamic>{};
        setState(() {
          _users = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
          _lastPage = meta['last_page'] is int ? meta['last_page'] : 1;
          _total = meta['total'] is int ? meta['total'] : 0;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat pengguna');
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
    _loadUsers();
  }

  void _onFilter(String? value) {
    setState(() => _role = value ?? 'all');
    _page = 1;
    _loadUsers();
  }

  void _loadMore() {
    if (_page >= _lastPage || _isLoading) return;
    setState(() => _page++);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Users',
      subtitle: 'Kelola pengguna platform',
      refreshable: true,
      onRefresh: _loadUsers,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_alt, size: 20),
          tooltip: 'Buat Akun',
          onPressed: _showCreateUserSheet,
        ),
      ],
      child: Column(
        children: [
          AdminFilterBar(
            searchController: _searchController,
            onSearch: _onSearch,
            onFilterChanged: _onFilter,
            filterValue: _role,
            filterLabel: 'Peran',
            filterOptions: const [
              ('all', 'Semua Peran'),
              ('admin', 'Admin'),
              ('owner', 'Pemilik'),
              ('customer', 'Pelanggan'),
            ],
          ),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: $_total pengguna',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadUsers)
                    : _users.isEmpty
                        ? const AdminEmptyState(
                            message: 'Tidak ada pengguna ditemukan')
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
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
                                itemCount: _users.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildUserCard(_users[index]),
                              ),
                            ),
                          ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = '${user['role']}';
    return AdminTapCard(
      onTap: () => _showUserDetail(user),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor(role).withOpacity(0.15),
                child: Text(
                  _firstChar(user['name']),
                  style: TextStyle(
                    color: roleColor(role),
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
                      '${user['name'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${user['phone']?.toString().isEmpty == true ? '-' : user['phone'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              AdminBadge(roleReplace(role), roleColor(role)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${user['email'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ),
              AdminBadge(
                user['is_active'] == true ? 'Aktif' : 'Nonaktif',
                user['is_active'] == true ? AppTheme.success : AppTheme.danger,
              ),
            ],
          ),
          if (user['created_at'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bergabung ${formatDate(user['created_at'])}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    if (_users.isEmpty && _page <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _page > 1 ? () {
              setState(() => _page--);
              _loadUsers();
            } : null,
            child: const Text('Sebelumnya'),
          ),
          Text(
            'Halaman $_page dari $_lastPage',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          TextButton(
            onPressed: _page < _lastPage ? () {
              setState(() => _page++);
              _loadUsers();
            } : null,
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateUserSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateUserSheet(),
    );
    if (created == true) {
      _page = 1;
      _loadUsers();
    }
  }

  Future<void> _showUserDetail(Map<String, dynamic> user) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(
        user: user,
        onChanged: _loadUsers,
      ),
    );
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

  static Color roleColor(String role) {
    switch (role) {
      case 'super_admin':
      case 'admin':
        return AppTheme.danger;
      case 'owner':
        return AppTheme.success;
      case 'customer':
        return AppTheme.info;
      default:
        return AppTheme.textMuted;
    }
  }

  static String roleReplace(String role) =>
      role.replaceAll('_', ' ').toUpperCase();

  static String _firstChar(dynamic name) {
    final text = name?.toString() ?? '';
    return text.isEmpty ? '?' : text[0].toUpperCase();
  }
}

// ─── Buat / edit role ─────────────────────────────────

class _CreateUserSheet extends StatefulWidget {
  const _CreateUserSheet();

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'owner';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.post(ApiConstants.adminUsers, data: {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'password': _password.text,
        'role': _role,
      });
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal membuat akun';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
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
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.danger),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: const [
                  DropdownMenuItem(value: 'owner', child: Text('Pemilik Studio')),
                  DropdownMenuItem(value: 'customer', child: Text('Pelanggan')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'owner'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary),
                            )
                          : const Text('Buat Akun'),
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
}

class _EditRoleSheet extends StatefulWidget {
  final Map<String, dynamic> user;

  const _EditRoleSheet({required this.user});

  @override
  State<_EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<_EditRoleSheet> {
  late String _role;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = '${widget.user['role']}';
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.put(
        ApiConstants.adminUserDetail(widget.user['id']),
        data: {'role': _role},
      );
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = response['message'] ?? 'Gagal mengubah role';
          _saving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuper = widget.user['role'] == 'super_admin';
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
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
              'Ubah role untuk ${widget.user['name']}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (isSuper)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '⚠ Super admin tidak bisa diubah role-nya',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.warning),
                ),
              ),
            if (_error != null) ...[
              Text('Error: $_error',
                  style: const TextStyle(color: AppTheme.danger, fontSize: 12.5)),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Peran'),
              items: [
                const DropdownMenuItem(value: 'customer', child: Text('Pelanggan')),
                const DropdownMenuItem(value: 'owner', child: Text('Pemilik Studio')),
                const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                if (isSuper)
                  const DropdownMenuItem(
                      value: 'super_admin', child: Text('Super Admin')),
              ],
              onChanged: isSuper
                  ? null
                  : (v) => setState(() => _role = v ?? _role),
            ),
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

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onChanged;

  const _UserDetailSheet({required this.user, required this.onChanged});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService
          .get(ApiConstants.adminUserDetail(widget.user['id']));
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
    final user = _detail ?? widget.user;
    final studios = user['studios'] is List ? user['studios'] as List : <dynamic>[];
    final bookings = user['bookings'] is List ? user['bookings'] as List : <dynamic>[];
    final stats = user['stats'] is Map ? Map<String, dynamic>.from(user['stats']) : <String, dynamic>{};

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Detail Pengguna',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadUser,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminErrorState(message: _error!, onRetry: _loadUser)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      _AdminUsersScreenState.roleColor(user['role'])
                                          .withOpacity(0.15),
                                  child: Text(
                                    _AdminUsersScreenState._firstChar(user['name']),
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: _AdminUsersScreenState.roleColor(user['role']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${user['name'] ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        '${user['email'] ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AdminBadge(
                                      _AdminUsersScreenState.roleReplace('${user['role']}'),
                                      _AdminUsersScreenState.roleColor(user['role']),
                                    ),
                                    const SizedBox(height: 4),
                                    AdminBadge(
                                      user['is_active'] == true ? 'Aktif' : 'Nonaktif',
                                      user['is_active'] == true
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _statTile(
                                      '${parseNum(stats['total_bookings']).toInt()}',
                                      'Total Booking'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statTile(
                                      idr(parseNum(stats['total_spent'])),
                                      'Total Belanja'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statTile(
                                      '${studios.length}',
                                      'Studio Dimiliki'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const AdminSectionTitle('Studio Dimiliki'),
                            const SizedBox(height: 10),
                            if (studios.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Tidak ada studio',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ...studios.map((s) {
                                final studio = Map<String, dynamic>.from(s);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.storefront_outlined,
                                            size: 20, color: AppTheme.accent),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${studio['name'] ?? '-'}',
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        AdminBadge(
                                          studio['is_verified'] == true
                                              ? 'Terverifikasi'
                                              : 'Belum Verified',
                                          studio['is_verified'] == true
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                        ),
                                        const SizedBox(width: 6),
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
                                  ),
                                );
                              }).toList(),
                            const SizedBox(height: 16),
                            const AdminSectionTitle('Booking Terbaru'),
                            const SizedBox(height: 10),
                            if (bookings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Tidak ada booking',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ...bookings.map((b) {
                                final item = Map<String, dynamic>.from(b);
                                final status = '${item['status']}';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item['booking_code'] ?? '-'}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.accent),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item['studio'] is Map ? (item['studio'] as Map)['name'] ?? '-' : item['studio'] ?? '-'} · ${formatDate(item['date'])}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          idr(parseNum(item['amount'])),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(width: 6),
                                        AdminBadge(
                                          bookingStatusLabel(status),
                                          bookingStatusColor(status),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _AdminUsersScreenState()
                        ._toggleUserAsDetail(
                            context, user, widget.onChanged),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    child: Text(
                        user['is_active'] == true ? 'Nonaktifkan' : 'Aktifkan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _AdminUsersScreenState()
                        ._editRoleAsDetail(context, user, widget.onChanged),
                    child: const Text('Ubah Role'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

extension _UserActions on _AdminUsersScreenState {
  Future<void> _toggleUserAsDetail(
      BuildContext context, Map<String, dynamic> user, VoidCallback onChanged) async {
    final active = user['is_active'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          '${active ? 'Nonaktifkan' : 'Aktifkan'} user \"${user['name']}\"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
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
    if (confirmed != true) return;
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        active
            ? ApiConstants.adminUserDeactivate(user['id'])
            : ApiConstants.adminUserActivate(user['id']),
      );
      if (context.mounted) {
        if (response['success'] == true) {
          _snack(response['message'] ?? 'Berhasil', AppTheme.success);
          if (Navigator.of(context).canPop()) Navigator.pop(context);
          onChanged();
        } else {
          throw Exception(response['message'] ?? 'Gagal');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
      }
    }
  }

  Future<void> _editRoleAsDetail(
      BuildContext context, Map<String, dynamic> user, VoidCallback onChanged) async {
    if (user['role'] == 'super_admin') {
      _snack('Super admin tidak bisa diubah role-nya', AppTheme.warning);
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRoleSheet(user: user),
    );
    if (saved == true) onChanged();
  }
}