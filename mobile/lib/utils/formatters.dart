import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final _dateFormats = {
    'short': DateFormat('dd MMM yyyy'),
    'long': DateFormat('dd MMMM yyyy'),
    'full': DateFormat('EEEE, dd MMMM yyyy'),
    'dayMonth': DateFormat('dd MMM'),
    'monthYear': DateFormat('MMMM yyyy'),
    'time': DateFormat('HH:mm'),
    'dateTime': DateFormat('dd MMM yyyy, HH:mm'),
  };

  /// Format currency (Rupiah)
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format currency with decimal
  static String currencyWithDecimal(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 2,
    ).format(amount);
  }

  /// Format date
  static String date(DateTime dateTime, {String format = 'short'}) {
    return _dateFormats[format]?.format(dateTime) ?? 
           DateFormat('dd MMM yyyy').format(dateTime);
  }

  /// Format time
  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Format date time
  static String dateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Format relative time (e.g., "2 jam yang lalu")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} minggu yang lalu';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} bulan yang lalu';
      } else {
        return '${(difference.inDays / 365).floor()} tahun yang lalu';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Format duration (e.g., "2 jam 30 menit")
  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes menit';
    }
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return '$hours jam';
    }
    
    return '$hours jam $remainingMinutes menit';
  }

  /// Format number with separator (e.g., "1.000")
  static String number(int number) {
    return NumberFormat('#,##0', 'id_ID').format(number);
  }

  /// Format rating (e.g., "4.5")
  static String rating(double? rating) {
    if (rating == null) return '-';
    return rating.toStringAsFixed(1);
  }

  /// Format phone number
  static String phone(String phone) {
    if (phone.startsWith('0')) {
      return '+62${phone.substring(1)}';
    }
    if (phone.startsWith('62')) {
      return '+$phone';
    }
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+62$phone';
  }

  /// Format booking code
  static String bookingCode(String code) {
    // Add space every 4 characters for readability
    return code.replaceAllMapped(
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  /// Truncate text with ellipsis
  static String truncate(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
