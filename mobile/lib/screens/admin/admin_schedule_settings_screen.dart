import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import 'admin_widgets.dart';

class AdminScheduleSettingsScreen extends StatefulWidget {
  const AdminScheduleSettingsScreen({super.key});

  @override
  State<AdminScheduleSettingsScreen> createState() =>
      _AdminScheduleSettingsScreenState();
}

class _AdminScheduleSettingsScreenState
    extends State<AdminScheduleSettingsScreen> {
  final _weeklyRecipients = TextEditingController();
  final _dailyRecipients = TextEditingController();
  final _monthlyRecipients = TextEditingController();
  final _weeklyTime = TextEditingController();
  final _dailyTime = TextEditingController();
  final _monthlyTime = TextEditingController();

  bool _enabledWeekly = false;
  bool _enabledDaily = false;
  bool _enabledMonthly = false;
  int _weeklyDay = 1;
  int _monthlyDay = 1;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _lastSyncMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weeklyRecipients.dispose();
    _dailyRecipients.dispose();
    _monthlyRecipients.dispose();
    _weeklyTime.dispose();
    _dailyTime.dispose();
    _monthlyTime.dispose();
    super.dispose();
  }

Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      final response = await apiService.get(ApiConstants.adminEmailSchedule);
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};

      final weekly = _mapOrEmpty(data['weekly']);
      final daily = _mapOrEmpty(data['daily']);
      final monthly = _mapOrEmpty(data['monthly']);

      const dayNames = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ];

      final weeklyDayRaw = weekly['day'];
      int weeklyDayIdx;
      if (weeklyDayRaw is int) {
        weeklyDayIdx = weeklyDayRaw.clamp(1, 7);
      } else {
        weeklyDayIdx = dayNames.indexOf('${weeklyDayRaw ?? ''}'.toLowerCase());
        if (weeklyDayIdx <= 0) weeklyDayIdx = 1;
      }

      setState(() {
        _enabledWeekly = weekly['enabled'] == true;
        _enabledDaily = daily['enabled'] == true;
        _enabledMonthly = monthly['enabled'] == true;
        _weeklyDay = weeklyDayIdx;
        _monthlyDay = parseNum(monthly['day']).toInt().clamp(1, 28);
        _weeklyTime.text = _formatTime(weekly['time'] ?? '09:00');
        _dailyTime.text = _formatTime(daily['time'] ?? '08:00');
        _monthlyTime.text = _formatTime(monthly['time'] ?? '09:00');
        _weeklyRecipients.text = _joinEmails(weekly['recipients']);
        _dailyRecipients.text = _joinEmails(daily['recipients']);
        _monthlyRecipients.text = _joinEmails(monthly['recipients']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _formatTime(dynamic time) {
    final t = '${time ?? '09:00'}';
    return t.length >= 5 ? t.substring(0, 5) : t.padRight(5, '0');
  }

  Map<String, dynamic> _mapOrEmpty(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      return {'recipients': value};
    }
    return <String, dynamic>{};
  }

  String _joinEmails(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e').toList().join(', ');
    }
    return _stringListFromDynamic(value).join(', ');
  }

  List<String> _stringListFromDynamic(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e').toList();
    }
    if (value is String && value.isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _parseEmails(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final apiService = ApiService();
      const dayNames = [
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ];
      final response = await apiService.put(
        ApiConstants.adminEmailSchedule,
        data: {
          'weekly': {
            'enabled': _enabledWeekly,
            'day': dayNames[_weeklyDay % 7],
            'time': _weeklyTime.text,
            'recipients': _parseEmails(_weeklyRecipients),
          },
          'daily': {
            'enabled': _enabledDaily,
            'time': _dailyTime.text,
            'recipients': _parseEmails(_dailyRecipients),
          },
          'monthly': {
            'enabled': _enabledMonthly,
            'day': _monthlyDay,
            'time': _monthlyTime.text,
            'recipients': _parseEmails(_monthlyRecipients),
          },
        },
      );
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _saving = false;
          _lastSyncMessage = response['message'];
        });
        _snack('Pengaturan jadwal disimpan', AppTheme.success);
      } else {
        throw Exception(response['message'] ?? 'Gagal menyimpan pengaturan');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      _snack(_error ?? 'Gagal menyimpan', AppTheme.danger);
    }
  }

  Future<void> _sendNow(String type, String label) async {
    final recipient = await _promptEmail(label);
    if (recipient == null) return;
    try {
      final apiService = ApiService();
      final path = type == 'weekly'
          ? ApiConstants.adminEmailWeekly
          : type == 'daily'
              ? ApiConstants.adminEmailDaily
              : ApiConstants.adminEmailMonthly;
      final response = await apiService.post(path, data: {
        'recipient': recipient,
      });
      if (!mounted) return;
      if (response['success'] == true) {
        _snack('Laporan $label dikirim', AppTheme.success);
      } else {
        throw Exception(response['message'] ?? 'Gagal mengirim laporan');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), AppTheme.danger);
    }
  }

  Future<String?> _promptEmail(String label) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kirim Laporan $label Sekarang'),
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
    if (email == null || email.isEmpty) return null;
    return email;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Jadwal Laporan',
      subtitle: 'Pengaturan laporan email',
      refreshable: true,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _lastSyncMessage == null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_lastSyncMessage != null) ...[
                      Text(
                        _lastSyncMessage!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.success),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildWeeklyCard(),
                    const SizedBox(height: 12),
                    _buildDailyCard(),
                    const SizedBox(height: 12),
                    _buildMonthlyCard(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textPrimary),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Simpan Pengaturan'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildWeeklyCard() {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '📅 Laporan Mingguan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: const Text('Ringkasan performa satu minggu',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            value: _enabledWeekly,
            activeTrackColor: AppTheme.accent,
            onChanged: (v) => setState(() => _enabledWeekly = v),
          ),
          const Divider(color: AppTheme.border),
          _buildDropdown(
            label: 'Hari Kirim',
            value: _weeklyDay,
            items: [
              for (var i = 1; i <= 7; i++) DropdownMenuItem(value: i, child: Text(days[i - 1])),
            ],
            onChanged: (v) => setState(() => _weeklyDay = v ?? 1),
          ),
          const SizedBox(height: 8),
          _TimeField(
            controller: _weeklyTime,
            label: 'Jam Kirim',
            onTap: () => _pickTimeDialog((time) {
              _weeklyTime.text = time;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weeklyRecipients,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Penerima',
              hintText: 'admin@example.com, ops@example.com',
              prefixIcon: Icon(Icons.people_outline),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _sendNow('weekly', 'Mingguan'),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Kirim Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '🔁 Laporan Harian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: const Text('Ringkasan performa harian',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            value: _enabledDaily,
            activeTrackColor: AppTheme.accent,
            onChanged: (v) => setState(() => _enabledDaily = v),
          ),
          const Divider(color: AppTheme.border),
          _TimeField(
            controller: _dailyTime,
            label: 'Jam Kirim',
            onTap: () => _pickTimeDialog((time) {
              _dailyTime.text = time;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dailyRecipients,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Penerima',
              hintText: 'admin@example.com',
              prefixIcon: Icon(Icons.people_outline),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _sendNow('daily', 'Harian'),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Kirim Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '📆 Laporan Bulanan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: const Text('Ringkasan performa satu bulan',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            value: _enabledMonthly,
            activeTrackColor: AppTheme.accent,
            onChanged: (v) => setState(() => _enabledMonthly = v),
          ),
          const Divider(color: AppTheme.border),
          _buildDropdown(
            label: 'Tanggal Kirim',
            value: _monthlyDay,
            items: [
              for (var i = 1; i <= 28; i++)
                DropdownMenuItem(value: i, child: Text('Tanggal $i')),
            ],
            onChanged: (v) => setState(() => _monthlyDay = v ?? 1),
          ),
          const SizedBox(height: 8),
          _TimeField(
            controller: _monthlyTime,
            label: 'Jam Kirim',
            onTap: () => _pickTimeDialog((time) {
              _monthlyTime.text = time;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _monthlyRecipients,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Penerima',
              hintText: 'admin@example.com',
              prefixIcon: Icon(Icons.people_outline),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _sendNow('monthly', 'Bulanan'),
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Kirim Sekarang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: AppTheme.surfaceLighter,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.event_outlined),
      ),
    );
  }

  Future<void> _pickTimeDialog(ValueChanged<String> onPicked) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) => Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onPicked('$hh:$mm');
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

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onTap;

  const _TimeField({
    required this.controller,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLighter.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            Text(
              controller.text,
              style: const TextStyle(
                fontSize: 13,
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