import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/studio_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/formatters.dart';
import '../home/home_screen.dart';
import 'payment_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Studio studio;
  final StudioRoom room;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int totalAmount;
  final String notes;

  const BookingConfirmationScreen({
    super.key,
    required this.studio,
    required this.room,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.notes,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio Info
            _buildInfoCard(
              'Studio',
              widget.studio.name,
              Icons.studio,
            ),
            const SizedBox(height: 12),

            // Room Info
            _buildInfoCard(
              'Room',
              widget.room.name,
              Icons.meeting_room,
            ),
            const SizedBox(height: 12),

            // Date & Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEEE, dd MMMM yyyy').format(widget.date)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Text('${widget.startTime} - ${widget.endTime}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            if (widget.notes.isNotEmpty)
              _buildInfoCard('Notes', widget.notes, Icons.note),
            if (widget.notes.isNotEmpty) const SizedBox(height: 12),

            // Price Breakdown
            Card(
              color: AppTheme.accent[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildPriceRow(
                      'Rate',
                      '${Formatters.currency(widget.room.pricePerHour)}/hour',
                    ),
                    _buildPriceRow(
                      'Duration',
                      _calculateDuration(),
                    ),
                    const Divider(),
                    _buildPriceRow(
                      'Total',
                      Formatters.currency(widget.totalAmount),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Terms & Conditions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Cancellation must be done at least 2 hours before booking time\n'
                      '• Late arrivals may result in reduced booking time\n'
                      '• Please treat the studio equipment with care',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Confirm & Pay ${Formatters.currency(widget.totalAmount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    final startParts = widget.startTime.split(':');
    final endParts = widget.endTime.split(':');

    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final duration = endMinutes - startMinutes;
    final hours = duration ~/ 60;

    return '$hours hour${hours > 1 ? 's' : ''}';
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final bookingProvider = context.read<BookingProvider>();
      
      final booking = await bookingProvider.createBooking(
        studioId: widget.studio.id,
        roomId: widget.room.id,
        bookingDate: DateFormat('yyyy-MM-dd').format(widget.date),
        startTime: widget.startTime,
        endTime: widget.endTime,
        notes: widget.notes,
      );

      if (booking != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              booking: booking,
              totalAmount: widget.totalAmount,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingProvider.error ?? 'Failed to create booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
