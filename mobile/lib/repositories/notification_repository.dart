import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _api;

  NotificationRepository(this._api);

  /// Get user's notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await _api.get('/notifications', queryParameters: {'page': page});
    return {
      'notifications': response['data'],
      'meta': response['meta'],
    };
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    await _api.post('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _api.post('/notifications/read-all');
  }

  /// Delete notification
  Future<void> deleteNotification(int notificationId) async {
    await _api.delete('/notifications/$notificationId');
  }

  /// Delete all notifications
  Future<void> deleteAll() async {
    await _api.delete('/notifications');
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _api.get('/notifications/unread-count');
    return response['data']['unread_count'];
  }

  /// Store FCM token
  Future<void> storeFcmToken(String token) async {
    await _api.post('/notifications/fcm-token', data: {
      'fcm_token': token,
    });
  }
}
