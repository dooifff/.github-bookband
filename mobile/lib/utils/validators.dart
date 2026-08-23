class Validators {
  /// Validate email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email harus diisi';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password harus diisi';
    }
    
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password harus diisi';
    }
    
    if (value != password) {
      return 'Password tidak cocok';
    }
    
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama harus diisi';
    }
    
    if (value.length < 2) {
      return 'Nama minimal 2 karakter';
    }
    
    if (value.length > 100) {
      return 'Nama maksimal 100 karakter';
    }
    
    return null;
  }

  /// Validate phone number
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove spaces and dashes
    value = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Indonesian phone number validation
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,13}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }
    
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  /// Validate min length
  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    
    if (value.length < min) {
      return '$fieldName minimal $min karakter';
    }
    
    return null;
  }

  /// Validate max length
  static String? maxLength(String? value, int max, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > max) {
      return '$fieldName maksimal $max karakter';
    }
    
    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w- ./?%&=]*)?$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Format URL tidak valid';
    }
    
    return null;
  }

  /// Validate number
  static String? number(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    
    if (number <= 0) {
      return '$fieldName harus lebih dari 0';
    }
    
    return null;
  }

  /// Validate integer
  static String? integer(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (int.tryParse(value) == null) {
      return '$fieldName harus berupa bilangan bulat';
    }
    
    return null;
  }

  /// Validate time format (HH:mm)
  static String? time(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return 'Format waktu tidak valid (HH:mm)';
    }
    
    return null;
  }

  /// Validate date format (YYYY-MM-DD)
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Format tanggal tidak valid (YYYY-MM-DD)';
    }
    
    // Check if valid date
    final parts = value.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    
    if (year == null || month == null || day == null) {
      return 'Format tanggal tidak valid';
    }
    
    if (month < 1 || month > 12) {
      return 'Bulan tidak valid';
    }
    
    if (day < 1 || day > 31) {
      return 'Hari tidak valid';
    }
    
    return null;
  }

  /// Validate promo code
  static String? promoCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode promo harus diisi';
    }
    
    if (value.length < 3) {
      return 'Kode promo minimal 3 karakter';
    }
    
    if (value.length > 50) {
      return 'Kode promo maksimal 50 karakter';
    }
    
    // Allow only alphanumeric and some special characters
    final promoRegex = RegExp(r'^[a-zA-Z0-9-_]+$');
    if (!promoRegex.hasMatch(value)) {
      return 'Kode promo hanya boleh mengandung huruf, angka, strip, dan underscore';
    }
    
    return null;
  }

  /// Combine multiple validators
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
