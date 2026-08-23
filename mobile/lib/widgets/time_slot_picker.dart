import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TimeSlotPicker extends StatefulWidget {
  final List<Map<String, dynamic>> availableSlots;
  final String? selectedStartTime;
  final String? selectedEndTime;
  final Function(String startTime, String endTime) onTimeSelected;

  const TimeSlotPicker({
    super.key,
    required this.availableSlots,
    this.selectedStartTime,
    this.selectedEndTime,
    required this.onTimeSelected,
  });

  @override
  State<TimeSlotPicker> createState() => _TimeSlotPickerState();
}

class _TimeSlotPickerState extends State<TimeSlotPicker> {
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    if (widget.selectedStartTime != null && widget.selectedEndTime != null) {
      _selectedSlot = '${widget.selectedStartTime}-${widget.selectedEndTime}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.access_time, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'Tidak ada slot waktu tersedia',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Waktu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableSlots.map((slot) {
            final startTime = slot['start_time'] as String;
            final endTime = slot['end_time'] as String;
            final isAvailable = slot['is_available'] as bool? ?? true;
            final slotKey = '$startTime-$endTime';
            final isSelected = _selectedSlot == slotKey;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedSlot = slotKey;
                      });
                      widget.onTimeSelected(startTime, endTime);
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : isAvailable
                          ? AppTheme.cardColor
                          : AppTheme.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isAvailable
                            ? AppTheme.borderColor
                            : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  '$startTime - $endTime',
                  style: TextStyle(
                    color: isAvailable
                        ? isSelected
                            ? AppTheme.primaryColor
                            : Colors.white
                        : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Time range picker with start and end time selection
class TimeRangePicker extends StatefulWidget {
  final String? initialStartTime;
  final String? initialEndTime;
  final Function(String startTime, String endTime) onTimeRangeSelected;

  const TimeRangePicker({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
    required this.onTimeRangeSelected,
  });

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartTime != null) {
      final parts = widget.initialStartTime!.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (widget.initialEndTime != null) {
      final parts = widget.initialEndTime!.split(':');
      _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime ?? const TimeOfDay(hour: 9, minute: 0) : _endTime ?? const TimeOfDay(hour: 17, minute: 0);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });

      if (_startTime != null && _endTime != null) {
        widget.onTimeRangeSelected(
          _formatTime(_startTime!),
          _formatTime(_endTime!),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Jam',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeButton(
                label: 'Jam Mulai',
                time: _startTime,
                onTap: () => _selectTime(isStart: true),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward, color: Colors.grey),
            ),
            Expanded(
              child: _buildTimeButton(
                label: 'Jam Selesai',
                time: _endTime,
                onTap: () => _selectTime(isStart: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? _formatTime(time) : '--:--',
              style: TextStyle(
                color: time != null ? Colors.white : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
