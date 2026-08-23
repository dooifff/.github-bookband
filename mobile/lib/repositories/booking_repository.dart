import '../services/api_service.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final ApiService _api;

  BookingRepository(this._api);

  /// Create a new booking
  Future<BookingModel> createBooking({
    required int studioId,
    required int roomId,
    required String date,
    required String startTime,
    required String endTime,
    int? bandId,
    String? promoCode,
    String? notes,
  }) async {
    final response = await _api.post('/bookings', data: {
      'studio_id': studioId,
      'room_id': roomId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      if (bandId != null) 'band_id': bandId,
      if (promoCode != null) 'promo_code': promoCode,
      if (notes != null) 'notes': notes,
    });

    return BookingModel.fromJson(response['data']);
  }

  /// Get user's bookings
  Future<Map<String, dynamic>> getBookings({
    String? status,
    int page = 1,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
    };

    if (status != null) queryParams['status'] = status;

    final response = await _api.get('/bookings', queryParameters: queryParams);

    return {
      'bookings': (response['data'] as List)
          .map((json) => BookingModel.fromJson(json))
          .toList(),
      'meta': response['meta'],
    };
  }

  /// Get booking detail
  Future<BookingModel> getBooking(int bookingId) async {
    final response = await _api.get('/bookings/$bookingId');
    return BookingModel.fromJson(response['data']);
  }

  /// Get booking by code
  Future<BookingModel> getBookingByCode(String code) async {
    final response = await _api.get('/bookings/code/$code');
    return BookingModel.fromJson(response['data']);
  }

  /// Cancel booking
  Future<BookingModel> cancelBooking(int bookingId, {String? reason}) async {
    final response = await _api.post('/bookings/$bookingId/cancel', data: {
      if (reason != null) 'reason': reason,
    });

    return BookingModel.fromJson(response['data']);
  }

  /// Create payment for booking
  Future<Map<String, dynamic>> createPayment({
    required int bookingId,
    required String method,
    String? provider,
  }) async {
    final response = await _api.post('/payments', data: {
      'booking_id': bookingId,
      'method': method,
      if (provider != null) 'provider': provider,
    });

    return response['data'];
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentCode) async {
    final response = await _api.get('/payments/$paymentCode/status');
    return response['data'];
  }

  /// Get payment history
  Future<Map<String, dynamic>> getPaymentHistory({int page = 1}) async {
    final response = await _api.get('/payment-history', queryParameters: {'page': page});
    return {
      'payments': response['data'],
      'meta': response['meta'],
    };
  }

  /// Validate promo code
  Future<Map<String, dynamic>> validatePromo({
    required String code,
    required double bookingAmount,
  }) async {
    final response = await _api.post('/promos/validate', data: {
      'code': code,
      'booking_amount': bookingAmount,
    });

    return response['data'];
  }
}
