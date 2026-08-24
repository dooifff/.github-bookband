import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/studio_model.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/studio_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/time_slot_picker.dart';
import 'booking_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final Studio studio;

  const BookingScreen({super.key, required this.studio});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  StudioRoom? _selectedRoom;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  String? _selectedEndTime;
  final _notesController = TextEditingController();
  int _selectedSlotIndex = -1;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Studio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accent[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.studio, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studio.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.studio.city}, ${widget.studio.province}',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Room
            const Text(
              'Select Room',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.studio.rooms.length,
                itemBuilder: (context, index) {
                  final room = widget.studio.rooms[index];
                  final isSelected = _selectedRoom?.id == room.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRoom = room;
                        _selectedStartTime = null;
                        _selectedEndTime = null;
                        _selectedSlotIndex = -1;
                      });
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent[50] : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.accent : AppTheme.border,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            room.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.accent[700] : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(room.pricePerHour),
                            style: TextStyle(
                              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max ${room.capacity} people',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Select Date
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14, // Next 14 days
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = DateUtils.isSameDay(_selectedDate, date);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _selectedStartTime = null;
                        _selectedEndTime = null;
                        _selectedSlotIndex = -1;
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accent : AppTheme.surfaceLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd').format(date),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Select Time
            if (_selectedRoom != null) ...[
              const Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TimeSlotPicker(
                studioId: widget.studio.id,
                roomId: _selectedRoom!.id,
                date: _selectedDate,
                onSlotSelected: (startTime, endTime, index) {
                  setState(() {
                    _selectedStartTime = startTime;
                    _selectedEndTime = endTime;
                    _selectedSlotIndex = index;
                  });
                },
                selectedIndex: _selectedSlotIndex,
              ),
              const SizedBox(height: 24),
            ],

            // Notes
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requests?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Summary
            if (_selectedRoom != null &&
                _selectedStartTime != null &&
                _selectedEndTime != null) ...[
              Card(
                color: AppTheme.accent[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildSummaryRow('Room', _selectedRoom!.name),
                      _buildSummaryRow('Date', DateFormat('dd MMMM yyyy').format(_selectedDate)),
                      _buildSummaryRow('Time', '$_selectedStartTime - $_selectedEndTime'),
                      _buildSummaryRow('Duration', _calculateDuration()),
                      const Divider(),
                      _buildSummaryRow(
                        'Total',
                        Formatters.currency(_calculateTotal()),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canBook() ? _proceedToBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Proceed to Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    if (_selectedStartTime == null || _selectedEndTime == null) return '-';

    final startParts = _selectedStartTime!.split(':');
    final endParts = _selectedEndTime!.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final duration = endMinutes - startMinutes;
    final hours = duration ~/ 60;
    final minutes = duration % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hours $minutes minutes';
    } else if (hours > 0) {
      return '$hours hours';
    } else {
      return '$minutes minutes';
    }
  }

  int _calculateTotal() {
    if (_selectedRoom == null || _selectedStartTime == null || _selectedEndTime == null) {
      return 0;
    }

    final startParts = _selectedStartTime!.split(':');
    final endParts = _selectedEndTime!.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final durationHours = (endMinutes - startMinutes) / 60;
    return (_selectedRoom!.pricePerHour * durationHours).toInt();
  }

  bool _canBook() {
    return _selectedRoom != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null;
  }

  void _proceedToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          studio: widget.studio,
          room: _selectedRoom!,
          date: _selectedDate,
          startTime: _selectedStartTime!,
          endTime: _selectedEndTime!,
          totalAmount: _calculateTotal(),
          notes: _notesController.text,
        ),
      ),
    );
  }
}
