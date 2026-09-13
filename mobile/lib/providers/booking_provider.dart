import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  
  List<Booking> _bookings = [];
  Booking? _selectedBooking;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _statusFilter;

  // Booking form data
  int? _selectedStudioId;
  int? _selectedRoomId;
  String? _selectedDate;
  String? _selectedStartTime;
  String? _selectedEndTime;
  String? _promoCode;
  Map<String, dynamic>? _promoResult;

  BookingProvider() : _bookingRepository = BookingRepository(ApiService());

  List<Booking> get bookings => _bookings;
  Booking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int? get selectedStudioId => _selectedStudioId;
  int? get selectedRoomId => _selectedRoomId;
  String? get selectedDate => _selectedDate;
  String? get selectedStartTime => _selectedStartTime;
  String? get selectedEndTime => _selectedEndTime;
  String? get promoCode => _promoCode;
  Map<String, dynamic>? get promoResult => _promoResult;

  /// Get user's bookings
  Future<void> getBookings({String? status, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _bookings = [];
      _hasMore = true;
      _statusFilter = status;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookingRepository.getBookings(
        status: status ?? _statusFilter,
        page: _currentPage,
      );

      final newBookings = result['bookings'] as List<Booking>;
      final meta = result['meta'];

      if (refresh) {
        _bookings = newBookings;
      } else {
        _bookings = [..._bookings, ...newBookings];
      }

      _hasMore = _currentPage < (meta['last_page'] ?? 1);
      _currentPage++;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get booking detail
  Future<void> getBookingDetail(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBooking = await _bookingRepository.getBooking(bookingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create booking
  ///
  /// The parameters override the values collected in the booking form, so a
  /// screen that already holds the selection can book in one call.
  Future<Booking?> createBooking({
    int? studioId,
    int? roomId,
    String? bookingDate,
    String? startTime,
    String? endTime,
    String? notes,
  }) async {
    final studio = studioId ?? _selectedStudioId;
    final room = roomId ?? _selectedRoomId;
    final date = bookingDate ?? _selectedDate;
    final start = startTime ?? _selectedStartTime;
    final end = endTime ?? _selectedEndTime;

    if (studio == null || room == null || date == null || start == null || end == null) {
      _error = 'Lengkapi data booking terlebih dahulu';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final booking = await _bookingRepository.createBooking(
        studioId: studio,
        roomId: room,
        date: date,
        startTime: start,
        endTime: end,
        promoCode: _promoCode,
        notes: notes,
      );

      _bookings.insert(0, booking);
      _clearBookingForm();
      
      _isLoading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedBooking = await _bookingRepository.cancelBooking(
        bookingId,
        reason: reason,
      );

      // Update booking in list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
      }

      if (_selectedBooking?.id == bookingId) {
        _selectedBooking = updatedBooking;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create payment
  Future<Map<String, dynamic>?> createPayment({
    required int bookingId,
    required String method,
    String? provider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payment = await _bookingRepository.createPayment(
        bookingId: bookingId,
        method: method,
        provider: provider,
      );

      _isLoading = false;
      notifyListeners();
      return payment;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Validate promo code
  Future<bool> validatePromo(String code, double bookingAmount) async {
    try {
      _promoResult = await _bookingRepository.validatePromo(
        code: code,
        bookingAmount: bookingAmount,
      );
      _promoCode = code;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _promoResult = null;
      _promoCode = null;
      notifyListeners();
      return false;
    }
  }

  /// Set booking form data
  void setStudio(int studioId) {
    _selectedStudioId = studioId;
    _selectedRoomId = null;
    notifyListeners();
  }

  void setRoom(int roomId) {
    _selectedRoomId = roomId;
    notifyListeners();
  }

  void setDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setStartTime(String time) {
    _selectedStartTime = time;
    notifyListeners();
  }

  void setEndTime(String time) {
    _selectedEndTime = time;
    notifyListeners();
  }

  /// Clear booking form
  void _clearBookingForm() {
    _selectedStudioId = null;
    _selectedRoomId = null;
    _selectedDate = null;
    _selectedStartTime = null;
    _selectedEndTime = null;
    _promoCode = null;
    _promoResult = null;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
