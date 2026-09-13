import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import 'admin_widgets.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen> {
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;
  bool _autoRefresh = false;
  Timer? _timer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.get(ApiConstants.adminPerformance),
        apiService.get(ApiConstants.adminPerformanceAlerts),
      ]);
      final perf = results[0];
      final alerts = results[1];
      if (perf['success'] == true) {
        setState(() {
          _data = Map<String, dynamic>.from(perf['data'] ?? {});
          _alerts = (alerts['data'] is List
                  ? alerts['data']
                  : alerts['alerts'] is List
                      ? alerts['alerts']
                      : <dynamic>[])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _lastUpdated = DateTime.now();
          _loading = false;
          _error = null;
        });
      } else {
        throw Exception(perf['message'] ?? 'Gagal memuat performa');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _toggleAutoRefresh(bool value) {
    setState(() => _autoRefresh = value);
    if (value) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Performance',
      subtitle: 'Monitoring server',
      refreshable: true,
      onRefresh: _load,
      actions: [
        PopupMenuButton<_AutoRefresh>(
          icon: Icon(
            _autoRefresh ? Icons.autorenew : Icons.timer_outlined,
            size: 20,
            color: _autoRefresh ? AppTheme.accent : null,
          ),
          tooltip: 'Perbarui otomatis',
          onSelected: (value) => _toggleAutoRefresh(value.enabled),
          itemBuilder: (context) => [
            for (final option in _AutoRefresh.options)
              PopupMenuItem(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option.enabled == _autoRefresh
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: option.enabled == _autoRefresh
                          ? AppTheme.accent
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              ),
          ],
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
                      if (_lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Terakhir diperbarui: ${Formatters.time(_lastUpdated!)}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ),
                      ..._buildAlertBanners(),
                      const SizedBox(height: 8),
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      _buildDetailSection(),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildAlertBanners() {
    return _alerts.map((a) {
      final severity = '${a['severity']}';
      final critical = severity == 'critical';
      final color = critical ? AppTheme.danger : AppTheme.warning;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              critical ? Icons.error_outline : Icons.warning_amber_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${a['message'] ?? 'Peringatan performa'}',
                style: TextStyle(fontSize: 13, color: color.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryCards() {
    final server = _data['server'] is Map
        ? Map<String, dynamic>.from(_data['server'])
        : <String, dynamic>{};
    final memory = server['memory'] is Map
        ? Map<String, dynamic>.from(server['memory'])
        : <String, dynamic>{};
    final disk = server['disk'] is Map
        ? Map<String, dynamic>.from(server['disk'])
        : <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Ringkasan'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Penggunaan CPU',
                value: '${parseNum(server['cpu_usage']).toStringAsFixed(1)}%',
                icon: Icons.speed,
                color: _meterColor(
                    parseNum(server['cpu_usage']).toDouble(),
                    warning: 70,
                    critical: 90),
                note: '${server['uptime'] ?? '-'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Memori',
                value:
                    '${parseNum(memory['percentage']).toStringAsFixed(1)}%',
                icon: Icons.memory_outlined,
                color: _meterColor(parseNum(memory['percentage']).toDouble(),
                    warning: 70, critical: 85),
                note: '${memory['used']} / ${memory['total']}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Disk',
                value: '${parseNum(disk['percentage']).toStringAsFixed(1)}%',
                icon: Icons.storage_outlined,
                color: _meterColor(parseNum(disk['percentage']).toDouble(),
                    warning: 80, critical: 90),
                note: '${disk['used']} / ${disk['total']}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Waktu Respons',
                value:
                    '${parseNum(_data['response_time_ms']).toStringAsFixed(0)}ms',
                icon: Icons.timer_outlined,
                color: AppTheme.info,
                note: 'Respon API',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildGauge(
                'CPU',
                parseNum(server['cpu_usage']).toDouble(),
                warning: 70,
                critical: 90,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGauge(
                'Memori',
                parseNum(memory['percentage']).toDouble(),
                warning: 70,
                critical: 85,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGauge(
                'Disk',
                parseNum(disk['percentage']).toDouble(),
                warning: 80,
                critical: 90,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _meterColor(double value, {required double warning, required double critical}) {
    if (value >= critical) return AppTheme.danger;
    if (value >= warning) return AppTheme.warning;
    return AppTheme.success;
  }

  Widget _buildGauge(String label, double value,
      {required double warning, required double critical}) {
    final color = _meterColor(value,
        warning: warning, critical: critical);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: (value / 100).clamp(0, 1),
                  strokeWidth: 7,
                  backgroundColor: AppTheme.surfaceLighter,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    final server = _data['server'] is Map
        ? Map<String, dynamic>.from(_data['server'])
        : <String, dynamic>{};
    final memory = server['memory'] is Map
        ? Map<String, dynamic>.from(server['memory'])
        : <String, dynamic>{};
    final disk = server['disk'] is Map
        ? Map<String, dynamic>.from(server['disk'])
        : <String, dynamic>{};
    final database = _data['database'] is Map
        ? Map<String, dynamic>.from(_data['database'])
        : <String, dynamic>{};
    final application = _data['application'] is Map
        ? Map<String, dynamic>.from(_data['application'])
        : <String, dynamic>{};
    final requests = application['requests'] is Map
        ? Map<String, dynamic>.from(application['requests'])
        : <String, dynamic>{};
    final resp = application['response_time'] is Map
        ? Map<String, dynamic>.from(application['response_time'])
        : <String, dynamic>{};
    final process = application['process'] is Map
        ? Map<String, dynamic>.from(application['process'])
        : <String, dynamic>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Detail'),
        const SizedBox(height: 12),
        _DetailCard(
          icon: Icons.dns_outlined,
          iconColor: AppTheme.accent,
          title: '🖥️ Server',
          rows: [
            ('Versi PHP', '${server['php_version'] ?? '-'}'),
            ('Laravel', '${server['laravel_version'] ?? '-'}'),
            ('Lingkungan', '${server['environment'] ?? '-'}'),
            ('Batas PHP', '${memory['php_limit'] ?? '-'}'),
            ('Ruang Disk', '${disk['free'] ?? '-'}'),
          ],
        ),
        const SizedBox(height: 10),
        _DetailCard(
          icon: Icons.storage_outlined,
          iconColor: AppTheme.info,
          title: '🗄️ Database',
          rows: [
            ('Driver', '${database['driver'] ?? '-'}'),
            ('Nama', '${database['database'] ?? '-'}'),
            ('Waktu Kueri', '${database['query_time_ms'] ?? '-'}ms'),
            ('Tabel', '${database['table_count'] ?? '-'}'),
            ('Ukuran', '${database['size'] ?? '-'}'),
          ],
        ),
        const SizedBox(height: 10),
        _DetailCard(
          icon: Icons.analytics_outlined,
          iconColor: AppTheme.warning,
          title: '📊 Aplikasi',
          rows: [
            ('Total Permintaan', Formatters.number(parseNum(requests['total']).toInt())),
            ('Tingkat Kesalahan',
                '${parseNum(requests['error_rate']).toStringAsFixed(2)}%'),
            ('Rata-rata Respons',
                '${parseNum(resp['average_ms']).toStringAsFixed(1)}ms'),
            ('Pengguna Aktif', '${parseNum(application['active_users']).toInt()}'),
          ],
        ),
        const SizedBox(height: 10),
        _DetailCard(
          icon: Icons.settings_outlined,
          iconColor: AppTheme.success,
          title: '⚙️ Proses',
          rows: [
            ('PID', '${process['pid'] ?? '-'}'),
            ('Memory Peak', '${process['memory_peak'] ?? '-'}'),
            ('Status Database', '${database['status'] ?? '-'}'),
          ],
        ),
      ],
    );
  }
}

class _AutoRefresh {
  final String label;
  final bool enabled;
  const _AutoRefresh(this.label, this.enabled);
  static const options = [
    _AutoRefresh('Off', false),
    _AutoRefresh('Setiap 15 detik', true),
  ];
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<(String, String)> rows;

  const _DetailCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows
              .map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.$1,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                        Text(
                          row.$2,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}