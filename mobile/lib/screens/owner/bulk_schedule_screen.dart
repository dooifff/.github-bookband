import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../repositories/studio_repository.dart';

class BulkScheduleScreen extends StatefulWidget {
  final int studioId;
  final int roomId;
  final String roomName;

  const BulkScheduleScreen({
    super.key,
    required this.studioId,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<BulkScheduleScreen> createState() => _BulkScheduleScreenState();
}

class _BulkScheduleScreenState extends State<BulkScheduleScreen> {
  String _selectedMode = 'dates';
  List<DateTime> _selectedDates = [];
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<int> _selectedDaysOfWeek = [];
  String _reason = '';
  bool _isLoading = false;

  final List<String> _dayNames = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Blokir Jadwal Massal'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomInfo(),
            const SizedBox(height: 20),
            _buildModeSelector(),
            const SizedBox(height: 20),
            _buildModeContent(),
            const SizedBox(height: 20),
            _buildReasonField(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.meeting_room,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Studio ID: ${widget.studioId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOption(
              'dates',
              'Tanggal Tertentu',
              Icons.calendar_month,
            ),
          ),
          Expanded(
            child: _buildModeOption(
              'range',
              'Rentang Tanggal',
              Icons.date_range,
            ),
          ),
          Expanded(
            child: _buildModeOption(
              'recurring',
              'Berulang',
              Icons.repeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _selectedDates.clear();
          _startDate = null;
          _endDate = null;
          _selectedDaysOfWeek.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    switch (_selectedMode) {
      case 'dates':
        return _buildDatesPicker();
      case 'range':
        return _buildRangePicker();
      case 'recurring':
        return _buildRecurringPicker();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDatesPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Tanggal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _showDatePicker,
                child: const Text('+ Tambah Tanggal'),
              ),
            ],
          ),
          if (_selectedDates.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada tanggal dipilih',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDates.map((date) {
                return Chip(
                  label: Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedDates.remove(date);
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRangePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Rentang Tanggal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Tanggal Mulai',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'Tanggal Akhir',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  'Jam Mulai (opsional)',
                  _startTime,
                  (time) => setState(() => _startTime = time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  'Jam Akhir (opsional)',
                  _endTime,
                  (time) => setState(() => _endTime = time),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Hari Berulang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final isSelected = _selectedDaysOfWeek.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDaysOfWeek.remove(index);
                    } else {
                      _selectedDaysOfWeek.add(index);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    _dayNames[index].substring(0, 3),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Tanggal Mulai',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'Tanggal Akhir',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? DateFormat('dd MMM yyyy').format(value)
                  : 'Pilih tanggal',
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay? value,
    Function(TimeOfDay) onChanged,
  ) {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (time != null) {
          onChanged(time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value != null
                  ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
                  : 'Pilih jam',
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alasan (opsional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Maintenance, Event khusus, dll',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _reason = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Blokir Jadwal'),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && !_selectedDates.contains(date)) {
      setState(() {
        _selectedDates.add(date);
        _selectedDates.sort();
      });
    }
  }

  Future<void> _submitSchedule() async {
    // Validation
    if (_selectedMode == 'dates' && _selectedDates.isEmpty) {
      _showError('Pilih minimal satu tanggal');
      return;
    }

    if (_selectedMode == 'range' && (_startDate == null || _endDate == null)) {
      _showError('Pilih tanggal mulai dan akhir');
      return;
    }

    if (_selectedMode == 'recurring' && _selectedDaysOfWeek.isEmpty) {
      _showError('Pilih minimal satu hari');
      return;
    }

    if (_selectedMode == 'recurring' && (_startDate == null || _endDate == null)) {
      _showError('Pilih tanggal mulai dan akhir');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studioRepository = context.read<StudioRepository>();
      
      Map<String, dynamic> result;

      switch (_selectedMode) {
        case 'dates':
          result = await studioRepository.blockDates(
            widget.roomId,
            _selectedDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
            _reason.isNotEmpty ? _reason : null,
          );
          break;

        case 'range':
          result = await studioRepository.blockDateRange(
            widget.roomId,
            DateFormat('yyyy-MM-dd').format(_startDate!),
            DateFormat('yyyy-MM-dd').format(_endDate!),
            _startTime != null
                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                : null,
            _endTime != null
                ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                : null,
            _reason.isNotEmpty ? _reason : null,
          );
          break;

        case 'recurring':
          result = await studioRepository.blockRecurring(
            widget.roomId,
            _selectedDaysOfWeek,
            DateFormat('yyyy-MM-dd').format(_startDate!),
            DateFormat('yyyy-MM-dd').format(_endDate!),
            _startTime != null
                ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                : null,
            _endTime != null
                ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                : null,
            _reason.isNotEmpty ? _reason : null,
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil memblokir jadwal'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
