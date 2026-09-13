import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import 'admin_widgets.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _thresholds = {};
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.get(
          ApiConstants.adminPerformanceAlerts,
          queryParameters: {'per_page': 100},
        ),
        apiService.get(ApiConstants.adminPerformanceAlertStats),
        apiService.get(ApiConstants.adminPerformanceAlertThresholds),
      ]);
      final alerts = results[0];
      final stats = results[1];
      final thresholds = results[2];
      setState(() {
        _alerts = (alerts['data'] is List ? alerts['data'] : <dynamic>[])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _stats = stats['data'] is Map
            ? Map<String, dynamic>.from(stats['data'])
            : <String, dynamic>{};
        _thresholds = thresholds['data'] is Map
            ? Map<String, dynamic>.from(thresholds['data'])
            : <String, dynamic>{};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _clearHistory() async {
    final ok = await _confirm('Apakah Anda yakin ingin menghapus riwayat peringatan?');
    if (!ok) return;
    try {
      final apiService = ApiService();
      await apiService.delete(ApiConstants.adminPerformanceAlerts);
      _snack('Riwayat peringatan dihapus', AppTheme.success);
      _load();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case 'active':
        return _alerts.where((a) => a['status'] == 'active').toList();
      case 'critical':
        return _alerts
            .where((a) => a['severity'] == 'critical' && a['status'] == 'active')
            .toList();
      case 'warning':
        return _alerts
            .where((a) => a['severity'] == 'warning' && a['status'] == 'active')
            .toList();
      default:
        return _alerts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Alerts',
      subtitle: 'Peringatan performa',
      refreshable: true,
      onRefresh: _load,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, size: 20),
          tooltip: 'Hapus riwayat',
          onPressed: _clearHistory,
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatCards(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const AdminSectionTitle(
                              'Riwayat Peringatan'),
                          const Spacer(),
                          Text(
                            '(${_filtered.length})',
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_filtered.isEmpty)
                        const AdminEmptyState(
                            message: 'Tidak ada peringatan')
                      else
                        ..._filtered.map(_buildAlertCard),
                      const SizedBox(height: 16),
                      _buildThresholdsCard(),
                      const SizedBox(height: 16),
                      _buildByMetricCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Total',
                value: '${parseNum(_stats['total']).toInt()}',
                icon: Icons.notifications_outlined,
                color: AppTheme.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Aktif',
                value: '${parseNum(_stats['active']).toInt()}',
                icon: Icons.circle_outlined,
                color: AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Kritis',
                value: '${parseNum(_stats['critical']).toInt()}',
                icon: Icons.error_outline,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Peringatan',
                value: '${parseNum(_stats['warning']).toInt()}',
                icon: Icons.warning_amber_outlined,
                color: AppTheme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: '24 Jam Terakhir',
                value: '${parseNum(_stats['last_24h']).toInt()}',
                icon: Icons.schedule,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: '7 Hari Terakhir',
                value: '${parseNum(_stats['last_7d']).toInt()}',
                icon: Icons.calendar_view_week_outlined,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      ('all', 'Semua'),
      ('active', 'Aktif'),
      ('critical', 'Kritis'),
      ('warning', 'Peringatan'),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.$2, style: const TextStyle(fontSize: 12.5)),
                selected: _filter == f.$1,
                onSelected: (_) => setState(() => _filter = f.$1),
                selectedColor: AppTheme.accent.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _filter == f.$1
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
                  fontWeight:
                      _filter == f.$1 ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = '${alert['severity']}';
    final status = '${alert['status']}';
    final color = severity == 'critical'
        ? AppTheme.danger
        : severity == 'warning'
            ? AppTheme.warning
            : AppTheme.info;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3.5),
          top: const BorderSide(color: AppTheme.border),
          right: const BorderSide(color: AppTheme.border),
          bottom: const BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${alert['message'] ?? 'Peringatan'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              AdminBadge(
                severity.toUpperCase(),
                color,
              ),
              const SizedBox(width: 4),
              AdminBadge(
                status == 'active' ? 'ACTIVE' : 'RESOLVED',
                status == 'active' ? AppTheme.danger : AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Metric: ${alert['metric'] ?? '-'} · Value: ${alert['value'] ?? '-'} · Threshold: ${alert['threshold'] ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            _relativeTime(parseDate(alert['timestamp'])),
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
          if (status == 'resolved' && alert['resolved_at'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '✅ Resolved at ${formatDate(alert['resolved_at'])}',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.success),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Ambang Batas Peringatan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_thresholds.isEmpty)
            const Text('Tidak ada data',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
          else
            ..._thresholds.entries.map((entry) {
              final value = entry.value is Map
                  ? Map<String, dynamic>.from(entry.value)
                  : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.replaceAll('_', ' ').toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Warning: ≥ ${value['warning'] ?? '-'} · Critical: ≥ ${value['critical'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildByMetricCard() {
    final byMetric = _stats['by_metric'] is Map
        ? Map<String, dynamic>.from(_stats['by_metric'])
        : <String, dynamic>{};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Peringatan per Metrik',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (byMetric.isEmpty)
            const Text('Tidak ada data',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13))
          else
            ...byMetric.entries.map((entry) {
              final value = entry.value is Map
                  ? Map<String, dynamic>.from(entry.value)
                  : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.replaceAll('_', ' ').toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                    Row(
                      children: [
                        Text(
                          'Total ${parseNum(value['total']).toInt()}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.info),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kritis ${parseNum(value['critical']).toInt()}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.danger),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Warning ${parseNum(value['warning']).toInt()}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.warning),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '-';
    return Formatters.relativeTime(date);
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
            child: const Text('Ya', style: TextStyle(color: AppTheme.danger)),
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