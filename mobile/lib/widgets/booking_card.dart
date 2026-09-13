import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';

/// Booking summary card.
///
/// The owner and customer booking lists work with raw API maps, so the card
/// takes the flattened fields instead of a [Booking] instance.
class BookingCard extends StatelessWidget {
  final String? bookingCode;
  final String? customerName;
  final String? studioName;
  final String? roomName;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? status;
  final num? totalPrice;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  /// Shown for bookings that are still waiting for payment.
  final VoidCallback? onPay;

  /// Shown for completed bookings (review can only be written afterwards).
  final VoidCallback? onReview;

  const BookingCard({
    super.key,
    this.bookingCode,
    this.customerName,
    this.studioName,
    this.roomName,
    this.date,
    this.startTime,
    this.endTime,
    this.status,
    this.totalPrice,
    this.onTap,
    this.onCancel,
    this.onPay,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final statusValue = status ?? 'pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studioName?.isNotEmpty == true ? studioName! : 'Studio',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roomName?.isNotEmpty == true ? roomName! : 'Room',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(statusValue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.confirmation_number, bookingCode ?? '-'),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(Icons.person, customerName ?? '-'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(Icons.calendar_today, _formatDate(date)),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.access_time,
                  '${startTime ?? '--:--'} - ${endTime ?? '--:--'}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(totalPrice),
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((statusValue == 'pending' ||
                        statusValue == 'awaiting_payment') &&
                    onPay != null)
                  FilledButton.tonal(
                    onPressed: onPay,
                    child: const Text('Bayar'),
                  ),
                if (statusValue == 'completed' && onReview != null)
                  FilledButton.tonal(
                    onPressed: onReview,
                    child: const Text('Beri Ulasan'),
                  ),
                if (statusValue == 'pending' || statusValue == 'awaiting_payment')
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                    ),
                    child: const Text('Batalkan'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusValue) {
    final statusColor = _getStatusColor(statusValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusText(statusValue),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _formatCurrency(num? amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount ?? 0);
  }

  Color _getStatusColor(String statusValue) {
    switch (statusValue) {
      case 'pending':
      case 'awaiting_payment':
        return Colors.orange;
      case 'paid':
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String statusValue) {
    switch (statusValue) {
      case 'pending':
        return 'Pending';
      case 'awaiting_payment':
        return 'Menunggu Bayar';
      case 'paid':
        return 'Dibayar';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'ongoing':
        return 'Berlangsung';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'expired':
        return 'Kedaluwarsa';
      case 'failed':
        return 'Gagal';
      case 'refunded':
        return 'Dana Kembali';
      default:
        return statusValue;
    }
  }
}
