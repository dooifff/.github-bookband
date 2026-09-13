import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../admin/admin_widgets.dart' show parseNum, idr;
import 'owner_widgets.dart';

class OwnerRevenueScreen extends StatefulWidget {
  const OwnerRevenueScreen({super.key});

  @override
  State<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends State<OwnerRevenueScreen> {
  final _api = ApiService();
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _revenueByStudio = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];
  bool _isLoading = true;
  String? _error;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

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
      final response = await _api.get(ApiConstants.ownerRevenue);
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};
      final summary = data['summary'] is Map
          ? Map<String, dynamic>.from(data['summary'])
          : <String, dynamic>{};
      setState(() {
        _summary = summary;
        _revenueByStudio = _toList(data['revenue_by_studio']);
        _monthlyRevenue = _toList(data['monthly_revenue']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  static List<Map<String, dynamic>> _toList(dynamic value) {
    if (value is List) {
      return value
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return OwnerScaffold(
      title: 'Pendapatan',
      subtitle: 'Ringkasan keuangan usaha Anda',
      refreshable: true,
      onRefresh: _loadRevenue,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _error != null
              ? _OwnerError(message: _error!, onRetry: _loadRevenue)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _SectionTitle('RINGKASAN PENDAPATAN'),
                    const SizedBox(height: 10),
                    _SummaryGrid(summary: _summary),
                    const SizedBox(height: 20),
                    _SectionTitle('PENDAPATAN PER STUDIO'),
                    const SizedBox(height: 10),
                    if (_revenueByStudio.isEmpty)
                      const _EmptyBox(
                          icon: Icons.storefront_outlined,
                          message: 'Belum ada pendapatan studio')
                    else
                      ..._revenueByStudio.map(
                          (s) => _StudioRevenueTile(studio: s)),
                    const SizedBox(height: 20),
                    _SectionTitle('PENDAPATAN BULANAN'),
                    const SizedBox(height: 10),
                    _MonthlyChart(
                        data: _monthlyRevenue, monthNames: _monthNames),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle('TRANSAKSI TERAKHIR'),
                        ),
                        InkWell(
                          onTap: () => context.go('/owner/bookings'),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _RecentTransactions(),
                  ],
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('TOTAL', parseNum(summary['total_revenue']), AppTheme.accent,
          Icons.account_balance_wallet_outlined, 'Semua pendapatan'),
      _SummaryItem('BULAN INI', parseNum(summary['this_month']),
          AppTheme.info, Icons.calendar_month_outlined, 'Pendapatan berjalan'),
      _SummaryItem('BULAN LALU', parseNum(summary['last_month']),
          AppTheme.success, Icons.history_outlined, 'Bulan sebelumnya'),
      _SummaryItem('TAHUN INI', parseNum(summary['this_year']),
          const Color(0xFFB8953A), Icons.event_outlined, 'Pendapatan tahunan'),
      _SummaryItem('MENUNGGU BAYAR', parseNum(summary['pending_payments']),
          AppTheme.warning, Icons.schedule_outlined, 'Belum dibayar'),
      _SummaryItem('REFUND', parseNum(summary['refunded']), AppTheme.danger,
          Icons.replay_outlined, 'Dikembalikan'),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _SummaryCard(
                    item: items[0], accent: true)),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(item: items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SummaryCard(item: items[2])),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(item: items[3])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SummaryCard(item: items[4])),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(item: items[5])),
          ],
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String label;
  final num value;
  final Color color;
  final IconData icon;
  final String note;

  const _SummaryItem(this.label, this.value, this.color, this.icon, this.note);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;
  final bool accent;

  const _SummaryCard({required this.item, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: accent
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent, Color(0xFF6A5AE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            )
          : AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (accent ? AppTheme.primary : item.color)
                      .withOpacity(accent ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  item.icon,
                  size: 16,
                  color: accent ? AppTheme.primary : item.color,
                ),
              ),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: accent ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            idr(item.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
          Text(
            item.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: accent ? AppTheme.primary : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioRevenueTile extends StatelessWidget {
  final Map<String, dynamic> studio;

  const _StudioRevenueTile({required this.studio});

  @override
  Widget build(BuildContext context) {
    final name = '${studio['studio_name'] ?? studio['name'] ?? '-'}';
    final revenue = parseNum(studio['total_revenue'] ?? studio['revenue']);
    final transactions = parseNum(studio['transaction_count'] ?? studio['transactions']).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          OwnerAvatar(name: name, radius: 18, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$transactions transaksi',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            idr(revenue),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> monthNames;

  const _MonthlyChart({required this.data, required this.monthNames});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: data.isEmpty
          ? const _EmptyBox(
              icon: Icons.bar_chart_outlined, message: 'Belum ada data bulanan')
          : SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(data.length, (index) {
                  final item = data[index];
                  final revenue = parseNum(item['revenue']);
                  final maxRevenue = data
                      .map((d) => parseNum(d['revenue']))
                      .reduce((a, b) => a > b ? a : b);
                  final barHeight =
                      maxRevenue > 0 ? (revenue / maxRevenue) * 110 : 0;
                  final month =
                      '${item['month']}'.padLeft(2, '0');
                  final monthIndex =
                      int.tryParse(month) ?? 0;
                  final label = monthIndex >= 1 &&
                          monthIndex <= 12
                      ? monthNames[monthIndex - 1]
                      : month;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat.compact(locale: 'id')
                                .format(revenue.toDouble()),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight.clamp(4.0, 110.0).toDouble(),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accent,
                                  AppTheme.accent.withOpacity(0.55),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
    );
  }
}

class _RecentTransactions extends StatefulWidget {
  const _RecentTransactions();

  @override
  State<_RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<_RecentTransactions> {
  final _api = ApiService();
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _api.get(
        ApiConstants.ownerBookings,
        queryParameters: {'status': 'paid'},
      );
      final items = response['data'] is List ? response['data'] : <dynamic>[];
      setState(() {
        _transactions = items
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }
    if (_transactions.isEmpty) {
      return const _EmptyBox(
          icon: Icons.payments_outlined, message: 'Belum ada transaksi');
    }
    final shown = _transactions.take(5).toList();
    return Column(
      children: shown.map((tx) {
        final user = tx['user'] is Map
            ? Map<String, dynamic>.from(tx['user'])
            : <String, dynamic>{};
        final studio = tx['studio'] is Map
            ? Map<String, dynamic>.from(tx['studio'])
            : <String, dynamic>{};
        final room = tx['room'] is Map
            ? Map<String, dynamic>.from(tx['room'])
            : <String, dynamic>{};
        final pricing = tx['pricing'] is Map
            ? Map<String, dynamic>.from(tx['pricing'])
            : <String, dynamic>{};
        final amount = pricing.isNotEmpty
            ? parseNum(pricing['total'])
            : parseNum(tx['total']);
        final bookingCode = '${tx['booking_code'] ?? '-'}';
        final customer = '${user['name'] ?? '-'}';
        final place = room.isNotEmpty
            ? '${studio['name'] ?? ''} · ${room['name'] ?? ''}'
            : '${studio['name'] ?? '-'}';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              OwnerAvatar(name: customer),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingCode,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      customer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                idr(amount),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
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