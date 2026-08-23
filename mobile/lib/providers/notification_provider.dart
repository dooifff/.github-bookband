import 'package:flutter/material.dart';
import '../repositories/notification_repository.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  NotificationProvider() : _notificationRepository = NotificationRepository(ApiService());

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Get notifications
  Future<void> getNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _notificationRepository.getNotifications(page: _currentPage);

      final newNotifications = result['notifications'] as List<Map<String, dynamic>>;
      final meta = result['meta'];

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications = [..._notifications, ...newNotifications];
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

  /// Get unread count
  Future<void> getUnreadCount() async {
    try {
      _unreadCount = await _notificationRepository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationRepository.markAsRead(notificationId);
      
      // Update notification in list
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
      }

      // Decrease unread count
      if (_unreadCount > 0) {
        _unreadCount--;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      
      // Update all notifications in list
      for (var notification in _notifications) {
        notification['is_read'] = true;
      }

      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _notificationRepository.deleteNotification(notificationId);
      
      // Remove from list
      _notifications.removeWhere((n) => n['id'] == notificationId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete all notifications
  Future<void> deleteAll() async {
    try {
      await _notificationRepository.deleteAll();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Store FCM token
  Future<void> storeFcmToken(String token) async {
    try {
      await _notificationRepository.storeFcmToken(token);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
