import 'package:flutter/material.dart';
import '../repositories/booking_repository.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  
  Map<String, dynamic>? _currentPayment;
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  PaymentProvider() : _bookingRepository = BookingRepository(ApiService());

  Map<String, dynamic>? get currentPayment => _currentPayment;
  List<Map<String, dynamic>> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Create payment for booking
  Future<bool> createPayment({
    required int bookingId,
    required String method,
    String? provider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPayment = await _bookingRepository.createPayment(
        bookingId: bookingId,
        method: method,
        provider: provider,
      );

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

  /// Check payment status
  Future<Map<String, dynamic>?> checkPaymentStatus(String paymentCode) async {
    try {
      final status = await _bookingRepository.getPaymentStatus(paymentCode);
      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get payment history
  Future<void> getPaymentHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _paymentHistory = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookingRepository.getPaymentHistory(page: _currentPage);

      final newPayments = result['payments'] as List<Map<String, dynamic>>;
      final meta = result['meta'];

      if (refresh) {
        _paymentHistory = newPayments;
      } else {
        _paymentHistory = [..._paymentHistory, ...newPayments];
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

  /// Clear current payment
  void clearCurrentPayment() {
    _currentPayment = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
