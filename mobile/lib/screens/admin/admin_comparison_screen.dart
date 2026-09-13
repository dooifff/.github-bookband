import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminComparisonScreen extends StatefulWidget {
  const AdminComparisonScreen({super.key});

  @override
  State<AdminComparisonScreen> createState() => _AdminComparisonScreenState();
}

class _AdminComparisonScreenState extends State<AdminComparisonScreen> {
  DateTime _p1Start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _p1End = DateTime.now().subtract(const Duration(days: 1));
  DateTime _p2Start = DateTime.now().subtract(const Duration(days: 14));
  DateTime _p2End = DateTime.now().subtract(const Duration(days: 8));

  Map<String, dynamic>? _result;
  Map<String, dynamic> _trends = {};
  bool _loading = false;
  bool _loadingTrends = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runComparison();
  }

  String _d(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _runComparison() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        ApiConstants.adminPerformanceCompare,
        data: {
          'period1_start': _d(_p1Start),
          'period1_end': _d(_p1End),
          'period2_start': _d(_p2Start),
          'period2_end': _d(_p2End),
        },
      );
      if (response['success'] == true) {
        setState(() {
          _result = Map<String, dynamic>.from(response['data']);
          _loading = false;
        });
        _loadTrends();
      } else {
        throw Exception(response['message'] ?? 'Gagal membandingkan');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadTrends() async {
    setState(() => _loadingTrends = true);
    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.get(ApiConstants.adminPerformanceTrend('cpu'),
            queryParameters: {'days': 30}),
        apiService.get(ApiConstants.adminPerformanceTrend('memory'),
            queryParameters: {'days': 30}),
        apiService.get(ApiConstants.adminPerformanceTrend('response_time'),
            queryParameters: {'days': 30}),
        apiService.get(ApiConstants.adminPerformanceTrend('disk'),
            queryParameters: {'days': 30}),
      ]);
      final metrics = ['CPU', 'Memori', 'Waktu Respons', 'Disk'];
      final map = <String, dynamic>{};
      for (var i = 0; i < results.length; i++) {
        final trend = results[i]['data'] is Map
            ? (results[i]['data'] as Map)['trend']
            : results[i]['trend'];
        map[metrics[i]] = trend is List ? trend : <dynamic>[];
      }
      setState(() {
        _trends = map;
        _loadingTrends = false;
      });
    } catch (e) {
      setState(() => _loadingTrends = false);
    }
  }

  Future<void> _sendEmail() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Laporan Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Alamat Email',
            hintText: 'admin@example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        ApiConstants.adminEmailSend,
        data: {
          'recipient': email,
          'period1_start': _d(_p1Start),
          'period1_end': _d(_p1End),
          'period2_start': _d(_p2Start),
          'period2_end': _d(_p2End),
          'attach_pdf': true,
        },
      );
      if (mounted) {
        if (response['success'] == true) {
          _snack('Laporan terkirim', AppTheme.success);
        } else {
          throw Exception(response['message'] ?? 'Gagal mengirim');
        }
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Comparison',
      subtitle: 'Perbandingan performa periode',
      refreshable: true,
      onRefresh: _runComparison,
      actions: [
        IconButton(
          icon: const Icon(Icons.mail_outline, size: 20),
          tooltip: 'Kirim laporan email',
          onPressed: _sendEmail,
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _runComparison)
              : RefreshIndicator(
                  onRefresh: _runComparison,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      if (_result != null) ...[
                        _buildSummary(),
                        const SizedBox(height: 16),
                        _buildComparisonTable(),
                        const SizedBox(height: 16),
                        _buildTrends(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Pilih Periode Waktu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Periode 1 (Terbaru) Awal',
                  date: _p1Start,
                  onTap: () => _pick(1, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateField(
                  label: 'Akhir',
                  date: _p1End,
                  onTap: () => _pick(1, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Periode 2 (Sebelumnya) Awal',
                  date: _p2Start,
                  onTap: () => _pick(2, true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateField(
                  label: 'Akhir',
                  date: _p2End,
                  onTap: () => _pick(2, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _runComparison,
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: const Text('Bandingkan Periode'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(int period, bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (period == 1 ? (isStart ? _p1Start : _p1End) : (isStart ? _p2Start : _p2End)),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
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
    if (picked == null) return;
    setState(() {
      if (period == 1) {
        if (isStart) {
          _p1Start = picked;
        } else {
          _p1End = picked;
        }
      } else {
        if (isStart) {
          _p2Start = picked;
        } else {
          _p2End = picked;
        }
      }
    });
  }

  Widget _buildSummary() {
    final summary = _result!['summary'] is Map
        ? Map<String, dynamic>.from(_result!['summary'])
        : <String, dynamic>{};
    final regressions = summary['regressions'] is List
        ? List<Map<String, dynamic>>.from(
            summary['regressions'].map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];
    final improvements = summary['improvements'] is List
        ? List<Map<String, dynamic>>.from(
            summary['improvements'].map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];
    final hasRegressions = summary['has_regressions'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Period 1 Snapshots',
                value: '${_countOf(1)}',
                icon: Icons.looks_one_outlined,
                color: AppTheme.info,
                note: '${_d(_p1Start)} s.d. ${_d(_p1End)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Period 2 Snapshots',
                value: '${_countOf(2)}',
                icon: Icons.looks_two_outlined,
                color: AppTheme.info,
                note: '${_d(_p2Start)} s.d. ${_d(_p2End)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                label: 'Regressions',
                value: '${parseNum(summary['regression_count']).toInt()}',
                icon: Icons.trending_down,
                color: hasRegressions ? AppTheme.danger : AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminStatCard(
                label: 'Improvements',
                value: '${parseNum(summary['improvement_count']).toInt()}',
                icon: Icons.trending_up,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
        if (hasRegressions) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Performance Regressions Detected',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 6),
                ...regressions.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${r['metric']}: +${parseNum(r['change']).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    )),
              ],
            ),
          ),
        ],
        if (improvements.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Performance Improvements',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 6),
                ...improvements.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${r['metric']}: -${parseNum(r['change']).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  int _countOf(int period) {
    final key = period == 1 ? 'period1' : 'period2';
    final p = _result![key] is Map
        ? Map<String, dynamic>.from(_result![key])
        : <String, dynamic>{};
    final stats = p['stats'] is Map
        ? Map<String, dynamic>.from(p['stats'])
        : <String, dynamic>{};
    return parseNum(stats['count']).toInt();
  }

  Widget _buildComparisonTable() {
    final comparison = _result!['comparison'] is Map
        ? Map<String, dynamic>.from(_result!['comparison'])
        : <String, dynamic>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('Perbandingan'),
        const SizedBox(height: 10),
        ...comparison.entries.map((entry) {
          final value = entry.value is Map
              ? Map<String, dynamic>.from(entry.value)
              : <String, dynamic>{};
          final p1 = value['period1'] is Map
              ? Map<String, dynamic>.from(value['period1'])
              : <String, dynamic>{};
          final p2 = value['period2'] is Map
              ? Map<String, dynamic>.from(value['period2'])
              : <String, dynamic>{};
          final change = value['change'] is Map
              ? Map<String, dynamic>.from(value['change'])
              : <String, dynamic>{};
          final metric = '${entry.key}';
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${metric.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _formatValue(metric, parseNum(p1['avg'])),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '→',
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatValue(metric, parseNum(p2['avg'])),
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${_changeDirectionIcon(change)} '
                      '${parseNum(change['percent']).toStringAsFixed(1)}%'
                      ' (${_changeDirectionLabel(change)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _changeColor(change, value['regression'] == true),
                      ),
                    ),
                    const Spacer(),
                    AdminBadge(
                      value['regression'] == true ? 'Regression' : 'OK',
                      value['regression'] == true
                          ? AppTheme.danger
                          : AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _changeDirectionIcon(Map<String, dynamic> change) {
    final direction = '${change['direction']}';
    if (direction == 'increased') return '↑';
    if (direction == 'decreased') return '↓';
    return '→';
  }

  String _changeDirectionLabel(Map<String, dynamic> change) {
    final direction = '${change['direction']}';
    if (direction == 'increased') return 'naik';
    if (direction == 'decreased') return 'turun';
    return 'tetap';
  }

  Color _changeColor(Map<String, dynamic> change, bool regression) {
    final direction = '${change['direction']}';
    if (direction == 'decreased') return AppTheme.success;
    if (direction == 'unchanged') return AppTheme.textMuted;
    if (parseNum(change['percent']) > 20) return AppTheme.danger;
    return AppTheme.warning;
  }

  String _formatValue(String metric, num value) {
    if (metric.contains('time')) return '${value.toStringAsFixed(1)}ms';
    if (metric.contains('error_rate')) return '${value.toStringAsFixed(2)}%';
    if (metric.contains('requests_per_second')) return '${value.toStringAsFixed(1)} req/s';
    return '${value.toStringAsFixed(1)}%';
  }

  Widget _buildTrends() {
    if (_loadingTrends) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final metrics = [
      ('CPU', _trends['CPU']),
      ('Memori', _trends['Memori']),
      ('Waktu Respons', _trends['Waktu Respons']),
      ('Disk', _trends['Disk']),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionTitle('📈 Tren 30 Hari'),
        const SizedBox(height: 10),
        ...metrics.map((m) {
          final trend = m.$2 as List<dynamic>? ?? <dynamic>[];
          if (trend.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cardDecoration,
              child: Text(
                '${m.$1}: Belum ada data',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textMuted),
              ),
            );
          }
          num avg = 0, min = double.infinity, max = double.negativeInfinity;
          final label = m.$1 == 'Waktu Respons' || m.$1 == 'Disk'
              ? '%'
              : 'N/A';
          if (m.$1 == 'Waktu Respons') {
            for (final t in trend) {
              final item = Map<String, dynamic>.from(t);
              final v = parseNum(item['avg']);
              avg += v;
              if (v < min) min = v;
              if (v > max) max = v;
            }
            avg = trend.isEmpty ? 0 : avg / trend.length;
            final count = trend.length;
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${m.$1}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        '${count} data points',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rata-rata: ${avg.toStringAsFixed(1)}ms  '
                    'Min: ${min.toStringAsFixed(1)}ms  '
                    'Max: ${max.toStringAsFixed(1)}ms',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }
          // metrik persen (CPU/Memori/Disk)
          for (final t in trend) {
            final item = Map<String, dynamic>.from(t);
            final v = parseNum(item['avg']);
            avg += v;
            if (v < min) min = v;
            if (v > max) max = v;
          }
          avg = trend.isEmpty ? 0 : avg / trend.length;
          final avgPct = (avg / 100).clamp(0, 1).toDouble();
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${m.$1}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${trend.length} data points',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Min ${min.toStringAsFixed(1)}$label',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rata ${avg.toStringAsFixed(1)}$label',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Max ${max.toStringAsFixed(1)}$label',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avgPct,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceLighter,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
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
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLighter.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}